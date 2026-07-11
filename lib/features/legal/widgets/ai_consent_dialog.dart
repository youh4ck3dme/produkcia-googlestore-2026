import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/services/ai_consent_service.dart';

/// GDPR consent before first AI prompt (BizBot, autopilot refinement, etc.).
Future<bool> showAiConsentDialog(
  BuildContext context,
  AiConsentService consentService,
) async {
  if (await consentService.hasConsent()) return true;

  if (!context.mounted) return false;

  final accepted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.t(AppStr.gdprAiConsentTitle)),
      content: SingleChildScrollView(
        child: Text(dialogContext.t(AppStr.gdprAiConsentBody)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(dialogContext.t(AppStr.gdprAiConsentDecline)),
        ),
        TextButton(
          onPressed: () => dialogContext.push('/legal/privacy'),
          child: Text(dialogContext.t(AppStr.settingsPrivacy)),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(dialogContext.t(AppStr.gdprAiConsentAccept)),
        ),
      ],
    ),
  );

  if (accepted == true) {
    await consentService.grantConsent();
    return true;
  }
  return false;
}