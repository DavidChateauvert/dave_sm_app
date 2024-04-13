import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/api/firebase_api.dart';
import 'package:sm_app/pages/aboutUs.dart';
import 'package:sm_app/pages/contactUs.dart';
import 'package:sm_app/pages/home.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:sm_app/providers/notification_provider.dart';
import 'package:sm_app/providers/theme_provider.dart';
import 'package:sm_app/widgets/progress.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsPage extends StatefulWidget {
  final String currentUserId;

  SettingsPage({required this.currentUserId});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  logout() async {
    await googleSignIn.signOut();
    FirebaseApi().deleteUserToken(currentUser.id);
    FirebaseAuth.instance.signOut();
    Navigator.pop(context);
  }

  setThemeInFirestore() async {
    String currentTheme = Provider.of<ThemeProvider>(context, listen: false)
        .getThemeDataFormatString();
    await usersRef.doc(widget.currentUserId).update({
      "theme": currentTheme,
    });
  }

  setLocaleInFirestore() async {
    String currentLocale = Provider.of<LocaleProvider>(context, listen: false)
        .getLocaleFormatString();
    await usersRef.doc(widget.currentUserId).update({
      "locale": currentLocale,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      key: _scaffoldKey,
      child: isLoading
          ? circularProgress()
          : ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.settings,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32.0,
                    ),
                  ),
                ),
                Container(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(
                          CupertinoIcons.brightness_solid,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.change_theme,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () {
                          Provider.of<ThemeProvider>(context, listen: false)
                              .toggleTheme();
                          setThemeInFirestore();
                          ;
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(
                          CupertinoIcons.globe,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        title: Text(
                          AppLocalizations.of(context)!.change_language,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onBackground,
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () {
                          Provider.of<LocaleProvider>(context, listen: false)
                              .toggleLocale();
                          setLocaleInFirestore();
                        },
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(CupertinoIcons.bell),
                        title: Text(
                          AppLocalizations.of(context)!.reset_notifications,
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => Provider.of<NotificationProvider>(context,
                                listen: false)
                            .resetNotificationCount(),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(CupertinoIcons.info),
                        title: Text(
                          AppLocalizations.of(context)!.about_us,
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AboutUs(),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(CupertinoIcons.envelope),
                        title: Text(
                          AppLocalizations.of(context)!.contact_us,
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactUs(),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text(
                          AppLocalizations.of(context)!.log_out,
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 20.0,
                          ),
                        ),
                        onTap: () => logout(),
                      ),
                      const SizedBox(
                        height: 16.0,
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
