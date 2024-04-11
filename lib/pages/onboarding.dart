import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sm_app/models/user.dart';
import 'package:sm_app/pages/create_account.dart';
import 'package:sm_app/pages/onboarding_screens/screen-1.dart';
import 'package:sm_app/pages/onboarding_screens/screen-2.dart';
import 'package:sm_app/pages/onboarding_screens/screen-3.dart';
import 'package:sm_app/pages/onboarding_screens/screen-4.dart';
import 'package:sm_app/pages/onboarding_screens/screen-5.dart';
import 'package:sm_app/providers/locale_provider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class Onboarding extends StatefulWidget {
  final String userId;

  const Onboarding({required this.userId});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  PageController _pageController = PageController();
  int activePage = 0;

  showCreateAccount() async {
    final User user = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAccount(
          userId: widget.userId,
        ),
      ),
    );
    Navigator.pop(context, user);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Stack(
      children: [
        PageView(
          controller: _pageController,
          children: [
            OnboardingScreen1(),
            OnboardingScreen2(
              locale: Provider.of<LocaleProvider>(context, listen: false)
                  .getLocaleFormatString(),
            ),
            OnboardingScreen3(
              locale: Provider.of<LocaleProvider>(context, listen: false)
                  .getLocaleFormatString(),
            ),
            OnboardingScreen4(),
            OnboardingScreen5(
              goToCreateAccount: showCreateAccount,
            ),
          ],
          onPageChanged: (value) {
            setState(() {
              activePage = value;
            });
          },
        ),
        Container(
          alignment: Alignment(0, 0.80),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: activePage != 4
                    ? () {
                        _pageController.jumpToPage(4);
                      }
                    : null,
                child: Text(
                  activePage != 4 ? AppLocalizations.of(context)!.skip : "",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SmoothPageIndicator(
                controller: _pageController,
                count: 5,
                effect: WormEffect(
                  dotColor: Colors.white,
                  activeDotColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: activePage != 4
                    ? () {
                        _pageController.nextPage(
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeIn,
                        );
                      }
                    : null,
                child: Text(
                  activePage != 4 ? AppLocalizations.of(context)!.next : "",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ));
  }
}
