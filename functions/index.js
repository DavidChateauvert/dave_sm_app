/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */
const {onRequest} = require("firebase-functions/v2/https");
const {onSchedule} = require("firebase-functions/v2/scheduler");
const logger = require("firebase-functions/logger");
const functions = require("firebase-functions");
const admin = require('firebase-admin');
admin.initializeApp();

// The es6-promise-pool to limit the concurrency of promises.
// const PromisePool = require("es6-promise-pool").default;
// Maximum concurrent account deletions.
// const MAX_CONCURRENT = 3;
// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

exports.onCreateFriend = functions.firestore
    .document("/friends/{userId}/userFriends/{friendId}")
    .onCreate(async (snapshot, context) => {
        const lastWeekStartDate = new Date();
        lastWeekStartDate.setDate(lastWeekStartDate.getDate() - 7);   

        const userId = context.params.userId;
        const friendId = context.params.friendId;

        // Create followed users post ref
        const friendUserPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('userPosts')
            .where("timestamp", ">=", lastWeekStartDate);
        
        // Create following user timeline ref
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(friendId)
            .collection('timelinePosts');

        // Get followed users posts
        const querySnapshot = await friendUserPostsRef.get();

        // Add each user post to following user's timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                timelinePostsRef.doc(postId).set(postData);
            }
        });
});

exports.onDeleteFriend = functions.firestore
    .document("/friends/{userId}/userFriends/{friendId}")
    .onDelete(async (snapshot, context) => {
        console.log("Friend Deleted", snapshot.id);

        const userId = context.params.userId;
        const friendId = context.params.friendId;

        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(friendId)
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
        console.log("Post created after deploy");

        const postCreated = snapshot.data();
        const userId = context.params.userId;
        const postId = context.params.postId;
        const group = postCreated.hasOwnProperty('group') ? postCreated.group : undefined;
        let userRef

        if (!group) {
            userRef = admin.firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');
        } else {
            userRef = admin.firestore()
            .collection('groups')
            .doc(userId)
            .collection('userGroups')
            .doc(group)
            .collection('users');
        }

        // Get all followers who made follow the user who made the post
        // const userFriendsRef = admin.firestore()
        //     .collection('friends')
        //     .doc(userId)
        //     .collection('userFriends');

        const querySnapshot = await userRef.get();

        // The user

        admin
            .firestore()
            .collection('timeline')
            .doc(userId)
            .collection('timelinePosts')
            .doc(postId)
            .set(postCreated)

        // Add post to each followers timeline
        querySnapshot.docs.forEach(doc => {
            const friendId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(friendId)
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
        const group = postUpdated.hasOwnProperty('group') ? postUpdated.group : undefined;
        let userRef;

        if (!group) {
            userRef = admin.firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');
        } else {
            userRef = admin.firestore()
            .collection('groups')
            .doc(userId)
            .collection('userGroups')
            .doc(group)
            .collection('users');
        }

        // Get all firend who have the post
        // const userFriendsRef = admin.firestore()
        // .collection('friends')
        // .doc(userId)
        // .collection('userFriends');

        const querySnapshot = await userRef.get();

        // And the user
        admin
            .firestore()
            .collection('timeline')
            .doc(userId)
            .collection('timelinePosts')
            .doc(postId)
            .get().then(doc => {
                if (doc.exists) {
                    doc.ref.update(postUpdated);
                }
            });

        // Update post to each followers timeline
        querySnapshot.docs.forEach(doc => {
            const friendId = doc.id;

            admin
                .firestore()
                .collection('timeline')
                .doc(friendId)
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
        const group = snapshot.data().hasOwnProperty('group') ? snapshot.data().group : undefined;

        // Get the media URL from the snapshot data
        const mediaURL = snapshot.data().mediaUrl;

        // Delete post from user's timeline
        await admin.firestore()
            .collection('timeline')
            .doc(userId)
            .collection('timelinePosts')
            .doc(postId)
            .delete();
        
        let userRef;

        if (!group) {
            userRef = admin.firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');
        } else {
            userRef = admin.firestore()
            .collection('groups')
            .doc(userId)
            .collection('userGroups')
            .doc(group)
            .collection('users');
        }

        // Delete post from each follower's timeline
        // const userFriendsRef = admin.firestore()
        //     .collection('friends')
        //     .doc(userId)
        //     .collection('userFriends');

        const querySnapshot = await userRef.get();

        querySnapshot.docs.forEach(async doc => {
            const friendId = doc.id;

            await admin.firestore()
                .collection('timeline')
                .doc(friendId)
                .collection('timelinePosts')
                .doc(postId)
                .delete();
        }); 

        // Delete the photo from Firebase Storage
        if (mediaURL) {
            // Extract the path of the file in the storage bucket
            const filePath = decodeURIComponent(mediaURL.split('/o/')[1].split('?')[0]);
            
            // Delete the file from storage
            await admin.storage().bucket().file(filePath).delete();
        }
    });

exports.onDeleteUser = functions.firestore
    .document("/users/{userId}")
    .onDelete(async (snapshot, context) => {
        const userId = context.params.userId;

        // Delete user's token
        await admin
            .firestore()
            .collection('tokens')
            .doc(userId)
            .delete();

        // Delete user's posts
        const userPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('userPosts');

        const userPostsbatch = admin.firestore().batch();

        const userPostsQuerySnapshot = await userPostsRef.get();
        
        userPostsQuerySnapshot.forEach((doc) => {
            userPostsbatch.delete(doc.ref);
        });

        await userPostsbatch.commit();

        // Delete user's notification feed
        const feedRef = admin
            .firestore()
            .collection('feed')
            .doc(userId)
            .collection('feedItems');

        const feedBatch = admin.firestore().batch();

        const feedQuerySnapshot = await feedRef.get();
        
        feedQuerySnapshot.forEach((doc) => {
            feedBatch.delete(doc.ref);
        });

        await feedBatch.commit();

        // Delete user's timeline
        const timelineRef = admin
            .firestore()
            .collection('timeline')
            .doc(userId)
            .collection('feedItems');

        const timelineBatch = admin.firestore().batch();

        const timelineQuerySnapshot = await timelineRef.get();
        
        timelineQuerySnapshot.forEach((doc) => {
            timelineBatch.delete(doc.ref);
        });

        await timelineBatch.commit();

        // Delete user's messages
        const messagesRef = admin
            .firestore()
            .collection('messages')
            .doc(userId)
            .collection('and')

        const messagesQuerySnapshot = await messagesRef.get();

        messagesQuerySnapshot.docs.forEach(async (doc) => {
            const messageQuerySnapshot = await doc.ref.collection('message').get();

            messageQuerySnapshot.docs.forEach(async (doc2) => {
                doc2.ref.delete();
            });

            const messageRef = admin
                .firestore()
                .collection('messages')
                .doc(doc.id)
                .collection('and')
                .doc(userId)
                .collection('message')
            
            const messagesFriendsQuerySnapshot = await messageRef.get();

            await messagesFriendsQuerySnapshot.docs.forEach(async (doc3) => {
                await doc3.ref.delete();
            });

            await admin
                .firestore()
                .collection('messages')
                .doc(doc.id)
                .collection('and')
                .doc(userId)
                .delete();
            
            doc.ref.delete();
        });

        // Delete user's friends
        const friendsRef = admin
            .firestore()
            .collection('friends')
            .doc(userId)
            .collection('userFriends');

        const friendsQuerySnapshot = await friendsRef.get();

        friendsQuerySnapshot.docs.forEach(async (doc) => {
            await admin
                .firestore()
                .collection('friends')
                .doc(doc.id)
                .collection('userFriends')
                .doc(userId)
                .delete();
            
            await doc.ref.delete();
        });     

        // Delete followers
        const followingRef = admin
            .firestore()
            .collection('following')
            .doc(userId)
            .collection('userFollowing');

        const followingQuerySnapshot = await followingRef.get();

        followingQuerySnapshot.docs.forEach(async (doc) => {
            await admin
                .firestore()
                .collection('followers')
                .doc(doc.id)
                .collection('userFollowers')
                .doc(userId)
                .delete();
            
            await doc.ref.delete();
        });

        // Delete followers
        const followersRef = admin
            .firestore()
            .collection('followers')
            .doc(userId)
            .collection('userFollowers');

        const followersQuerySnapshot = await followersRef.get();

        followersQuerySnapshot.docs.forEach(async (doc) => {
            await admin
                .firestore()
                .collection('following')
                .doc(doc.id)
                .collection('userFollowing')
                .doc(userId)
                .delete();
            
            await doc.ref.delete();
        });

        // Delete user's group
        const groupRef = admin
            .firestore()
            .collection('groups')
            .doc(userId)
            .collection('feedItems');

        const groupBatch = admin.firestore().batch();

        const groupQuerySnapshot = await groupRef.get();
        
        groupQuerySnapshot.forEach((doc) => {
            groupBatch.delete(doc.ref);
        });

        await groupBatch.commit();
    });

    // exports.postCleanup = onSchedule("every day 00:00", async (event) => {
    //     const allUsers = admin.firestore().collection("users");
    //     const currentDate = new Date();
    //     const thirtyDaysAgo = new Date(currentDate.getTime() - (30 * 24 * 60 * 60 * 1000));
    
    //     const querySnapshot = await allUsers.get();
    
    //     querySnapshot.docs.forEach(async userDoc => {
    //         const userPosts = admin.firestore().collection("posts").doc(userDoc.id).collection("userPosts");
            
    //         const querySnapshot2 = await userPosts.get();
    
    //         querySnapshot2.docs.forEach(async postDoc => {
    //             const postTimestamp = postDoc.data().timestamp.toDate();
                
    //             if (postTimestamp < thirtyDaysAgo) {
    //                 logger.log(postDoc.data().postId);
    //                 // await postDoc.ref.delete();
    //             }
    //         });
    //     });
    
    //     logger.log("User cleanup finished");
    // });
    

