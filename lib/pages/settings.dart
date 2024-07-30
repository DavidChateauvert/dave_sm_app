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

  @override
  Widget build(BuildContext context) {
    final List<bool> _selectedTheme =
        Provider.of<ThemeProvider>(context, listen: false).defaultBoolList();
    final List<bool> _selectedLocale =
        Provider.of<LocaleProvider>(context, listen: false).defaultBoolList();
    return Drawer(
      key: _scaffoldKey,
      child: isLoading
          ? circularProgress(context)
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
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.theme,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          ToggleButtons(
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            isSelected: _selectedTheme,
                            onPressed: (int index) {
                              String theme;
                              if (index == 0) {
                                theme = "system";
                              } else if (index == 1) {
                                theme = "light";
                              } else {
                                theme = "dark";
                              }
                              Provider.of<ThemeProvider>(context, listen: false)
                                  .toggleThemeMode(theme, true);
                            },
                            renderBorder: false,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 32.0,
                                ),
                                child:
                                    Icon(CupertinoIcons.device_phone_portrait),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 32.0,
                                ),
                                child: Icon(CupertinoIcons.brightness_solid),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 32.0,
                                ),
                                child: Icon(CupertinoIcons.moon_fill),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24.0,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.language_type,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 20.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          ToggleButtons(
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            isSelected: _selectedLocale,
                            onPressed: (int index) {
                              String locale;
                              if (index == 0) {
                                locale = "en";
                              } else {
                                locale = "fr";
                              }
                              Provider.of<LocaleProvider>(context,
                                      listen: false)
                                  .toggleLocaleToParam(locale, true);
                            },
                            renderBorder: false,
                            children: <Widget>[
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 32.0,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .language_type_en,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 32.0,
                                ),
                                child: Text(
                                  AppLocalizations.of(context)!
                                      .language_type_fr,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onBackground,
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 24.0,
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
