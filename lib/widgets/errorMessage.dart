import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

showErrorMessage(BuildContext context, Object error) {
  String errorMessage;

  if (error is FirebaseException) {
    switch (error.code) {
      case 'unavailable':
        errorMessage = AppLocalizations.of(context)!.error_unavailable;
        break;
      case 'deadline-exceeded':
        errorMessage = AppLocalizations.of(context)!.error_deadline_exceeded;
        break;
      default:
        errorMessage =
            AppLocalizations.of(context)!.error_unknown(error.message ?? "");
    }
  } else if (error is PlatformException) {
    errorMessage =
        AppLocalizations.of(context)!.error_platform(error.message ?? "");
  } else {
    errorMessage =
        AppLocalizations.of(context)!.error_message(error.toString());
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(errorMessage)),
  );
}
