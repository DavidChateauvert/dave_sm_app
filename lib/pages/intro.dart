import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/models/user.dart' as DaveUser;
import 'package:sm_app/pages/onboarding.dart';
import 'package:sm_app/providers/locale_provider.dart';

class Intro extends StatefulWidget {
  final String userId;

  Intro({required this.userId});

  @override
  _IntroState createState() => _IntroState();
}

class _IntroState extends State<Intro> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<bool> _selectedLanguage = <bool>[true, false];

  showOnboarding() async {
    final DaveUser.User user = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Onboarding(
          userId: widget.userId,
        ),
      ),
    );
    Navigator.pop(context, user);
  }

  @override
  Widget build(context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              Color.fromARGB(255, 244, 186, 184),
              Color.fromARGB(255, 89, 36, 99),
            ],
          ),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Text(
              textAlign: TextAlign.center,
              AppLocalizations.of(context)!.welcome_dave,
              style: TextStyle(
                fontSize: 56.0,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Column(
              children: [
                Text(
                  textAlign: TextAlign.center,
                  AppLocalizations.of(context)!.select_language,
                  style: TextStyle(
                    fontSize: 24.0,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16.0),
                ToggleButtons(
                  direction: Axis.horizontal,
                  onPressed: (int index) {
                    setState(() {
                      for (int i = 0; i < _selectedLanguage.length; i++) {
                        _selectedLanguage[i] = i == index;
                      }
                      Provider.of<LocaleProvider>(context, listen: false)
                          .selectIntro(index);
                    });
                  },
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  selectedBorderColor: Theme.of(context).colorScheme.primary,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  fillColor: Colors.white,
                  color: Theme.of(context).colorScheme.primary,
                  isSelected: _selectedLanguage,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'English',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'Français',
                        style: TextStyle(
                          fontSize: 20.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Column(
              children: [
                IntrinsicWidth(
                  child: TextButton(
                    onPressed: () => showOnboarding(),
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.chevron_back,
                          color: Colors.transparent,
                        ),
                        Text(
                          AppLocalizations.of(context)!.continue_intro,
                          style: TextStyle(
                            fontSize: 36.0,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  height: 16.0,
                ),
                IntrinsicWidth(
                  child: TextButton(
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    },
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.chevron_back,
                          color: Colors.white,
                        ),
                        Text(
                          AppLocalizations.of(context)!.return_intro,
                          style: TextStyle(
                            fontSize: 20.0,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          color: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
