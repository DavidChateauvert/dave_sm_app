import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class OnboardingScreen5 extends StatelessWidget {
  final Function() goToCreateAccount;
  const OnboardingScreen5({
    super.key,
    required this.goToCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.secondary,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(
              textAlign: TextAlign.center,
              AppLocalizations.of(context)!.onboarding_screen_5_top,
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(
            height: 40.0,
          ),
          Padding(
            padding: const EdgeInsets.only(top: 32.0),
            child: IntrinsicWidth(
              child: TextButton(
                onPressed: () => goToCreateAccount(),
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.set_up_account,
                      style: TextStyle(
                        fontSize: 24.0,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Icon(
                      CupertinoIcons.forward,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
