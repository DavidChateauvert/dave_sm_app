import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<bool> checkInternetConnection() async {
  var connectivityResult = await (Connectivity().checkConnectivity());
  return connectivityResult != ConnectivityResult.none;
}

Widget showNoConnection(BuildContext context, Function retryFunction) {
  return Container(
    color: Theme.of(context).colorScheme.background,
    child: Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        const SizedBox(
          height: 16.0,
        ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0,
          ),
          child: Text(
            AppLocalizations.of(context)!.error_no_connection,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primaryContainer,
              fontStyle: FontStyle.normal,
              fontWeight: FontWeight.w600,
              fontSize: 32.0,
            ),
          ),
        ),
        const SizedBox(
          height: 16.0,
        ),
        ElevatedButton(
          onPressed: retryFunction as void Function()?,
          child: Text(AppLocalizations.of(context)!.retry),
        ),
      ],
    )),
  );
}
