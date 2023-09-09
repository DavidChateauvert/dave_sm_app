/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const {onRequest} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require('firebase-admin');
admin.initializeApp();
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started


exports.onCreateFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onCreate(async (snapshot, context) => {
        console.log("Followers Created : ", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        // Create followed users post ref
        const followedUserPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('userPosts');
        
        // Create following user timeline ref
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts'); 

        // Get followed users posts
        const querySnapshot = await followedUserPostsRef.get();

        // Add each user post to following user's timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        });
});

exports.onDeleteFollower = functions.firestore
    .document("/followers/{userId}/userFollowers/{followerId}")
    .onDelete(async (snapshot, context) => {
        console.log("Follower Deleted", snapshot.id);

        const userId = context.params.userId;
        const followerId = context.params.followerId;

        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.docs.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        })
});

exports.onCreatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onCreate(async (snapshot, context) => {

        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        // Get all followers who made follow the user who made the post
        const userFollowersRef = admin.firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        // Add post to each followers timeline
        querySnapshot.docs.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .set(postCreated)
        });
});


exports.onUpdatePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onUpdate(async (change, context) => {
        const postUpdated = change.after.data();
        const userId = context.params.userId;
        const postId = context.params.postId;

        // Get all followers who made the post
        const userFollowersRef = admin.firestore()
        .collection('followers')
        .doc(userId)
        .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        // Update post to each followers timeline
        querySnapshot.docs.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {
                    if (doc.exists) {
                        doc.ref.update(postUpdated);
                    }
                });
        });
});

exports.onDeletePost = functions.firestore
    .document('/posts/{userId}/userPosts/{postId}')
    .onDelete(async (snapshot, context) => {

        const userId = context.params.userId;
        const postId = context.params.postId;

        // Get all followers who made the post
        const userFollowersRef = admin.firestore()
        .collection('followers')
        .doc(userId)
        .collection('userFollowers');

        const querySnapshot = await userFollowersRef.get();

        // Delete post to each followers timeline
        querySnapshot.docs.forEach(doc => {
            const followerId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {
                    if (doc.exists) {
                        doc.ref.delete();
                    }
                });
        });
});

// Doit payer :(
// exports.autoDeleteExpiredPosts = functions.pubsub
//   .schedule('every 1 hours') // Run the function every hour
//   .onRun(async (context) => {
//     const currentTime = Date.now();
//     const expirationTime = currentTime - 60 * 1000; // 12 hours ago

//     const usersRef = admin.firestore().collection('users');
//     const usersSnapshot = await usersRef.get();

//     const batch = admin.firestore().batch();

//     usersSnapshot.forEach((userDoc) => {
//       const userId = userDoc.id;
//       const postsRef = admin.firestore().collection('posts').doc(userId).collection('userPosts');

//       postsRef
//         .where('timestamp', '<', expirationTime)
//         .get()
//         .then((querySnapshot) => {
//           querySnapshot.forEach((postDoc) => {
//             batch.delete(postDoc.ref);
//           });
//         });
//     });

//     await batch.commit();

//     return null;
// });
