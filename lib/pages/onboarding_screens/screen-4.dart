import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/providers/locale_provider.dart';

class OnboardingScreen4 extends StatelessWidget {
  const OnboardingScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              textAlign: TextAlign.center,
              AppLocalizations.of(context)!.onboarding_screen_4_top,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(
            height: 128,
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Image.asset(
                Provider.of<LocaleProvider>(context, listen: false)
                            .getLocaleFormatString() ==
                        "en"
                    ? 'assets/onboarding/screen-4-en.png'
                    : 'assets/onboarding/screen-4-fr.png',
              ),
            ),
          )
        ],
      ),
    );
  }
}
