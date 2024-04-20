import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class CleantTimeline extends StatefulWidget {
  final Function() handleCleanTimeline;
  const CleantTimeline({Key? key, required this.handleCleanTimeline})
      : super(key: key);

  @override
  State<CleantTimeline> createState() => _CleantTimelineState();
}

class _CleantTimelineState extends State<CleantTimeline> {
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 32.0),
          child: IntrinsicWidth(
            child: TextButton(
              onPressed: widget.handleCleanTimeline,
              child: Row(
                children: [
                  Icon(
                    Icons.remove_red_eye_sharp,
                    color: Theme.of(context).colorScheme.primaryContainer,
                  ),
                  SizedBox(
                    width: 8.0,
                  ),
                  Text(
                    AppLocalizations.of(context)!.clean_timeline,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      fontSize: 20.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
