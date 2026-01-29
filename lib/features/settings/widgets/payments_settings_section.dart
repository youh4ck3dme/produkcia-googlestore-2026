import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_section_header.dart';
import '../providers/settings_provider.dart';

class PaymentsSettingsSection extends ConsumerWidget {
  const PaymentsSettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      loading: () => const SizedBox(
          height: 56, child: Center(child: CircularProgressIndicator())),
      error: (e, st) => Text(context.t(AppStr.errorGeneric)),
      data: (settings) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BizSectionHeader(title: context.t(AppStr.paymentsTitle)),
            const SizedBox(height: 10),
            BizCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller:
                        TextEditingController(text: settings.iban ?? ''),
                    decoration: InputDecoration(
                      labelText: context.t(AppStr.ibanLabel),
                      hintText: context.t(AppStr.ibanHint),
                      helperText: context.t(AppStr.ibanHelper),
                    ),
                    onChanged: (v) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateIban(v);
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: settings.showQrOnInvoice,
                    onChanged: (v) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .updateShowQrOnInvoice(v);
                    },
                    title: Text(context.t(AppStr.showQrOnInvoice)),
                    subtitle: Text(context.t(AppStr.showQrOnInvoiceDesc)),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
