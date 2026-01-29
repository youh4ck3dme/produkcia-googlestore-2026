import 'package:flutter/material.dart';
import '../../core/i18n/app_strings.dart';
import '../../core/i18n/l10n.dart';
import 'biz_card.dart';
import 'biz_buttons.dart';

class MissingIbanCard extends StatelessWidget {
  const MissingIbanCard({super.key, required this.onGoSettings});
  final VoidCallback onGoSettings;

  @override
  Widget build(BuildContext context) {
    return BizCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.t(AppStr.missingIbanTitle),
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(context.t(AppStr.missingIbanBody)),
          const SizedBox(height: 12),
          BizPrimaryButton(
            label: context.t(AppStr.setNow),
            icon: Icons.settings,
            onPressed: onGoSettings,
          ),
        ],
      ),
    );
  }
}
