// lib/features/export/screens/export_screen.dart
// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../shared/widgets/biz_card.dart';
import '../../../shared/widgets/biz_buttons.dart';
import '../../../shared/widgets/biz_progress_list.dart';
import '../../../shared/widgets/biz_section_header.dart';
import '../../../shared/utils/biz_snackbar.dart';
import '../models/export_models.dart';
import '../providers/export_provider.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key, required this.uid});
  final String uid;

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportPeriod _period = _thisMonth();

  static ExportPeriod _thisMonth() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, 1);
    final to = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  static ExportPeriod _lastMonth() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month - 1, 1);
    final to = DateTime(now.year, now.month, 0, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  static ExportPeriod _thisQuarter() {
    final now = DateTime.now();
    final q = ((now.month - 1) ~/ 3) + 1;
    final startMonth = (q - 1) * 3 + 1;
    final from = DateTime(now.year, startMonth, 1);
    final to = DateTime(now.year, startMonth + 3, 0, 23, 59, 59);
    return ExportPeriod(from: from, to: to);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ExportState>(exportProvider, (previous, next) {
      if (previous?.result == null && next.result != null) {
        BizSnackbar.showSuccess(context, 'Export bol úspešne vygenerovaný!');
      }
      if (next.error != null && previous?.error != next.error) {
        BizSnackbar.showError(
            context, 'Chyba pri generovaní exportu: ${next.error}');
      }
    });

    final st = ref.watch(exportProvider);
    final ctrl = ref.read(exportProvider.notifier);

    final items = [
      BizProgressItem(context.t(AppStr.exportInvoicesPdf),
          done: st.progress.pdfDone),
      BizProgressItem(context.t(AppStr.exportExpensesPhotos),
          done: st.progress.photosDone),
      BizProgressItem(context.t(AppStr.exportSummaryCsv),
          done: st.progress.csvDone),
      BizProgressItem(context.t(AppStr.exportDataJson),
          done: st.progress.jsonDone),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(context.t(AppStr.exportForAccountantTitle))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          BizSectionHeader(title: context.t(AppStr.periodLabel)),
          const SizedBox(height: 10),
          BizCard(
            child: Column(
              children: [
                _PeriodPresetTile(
                  label: 'Tento mesiac',
                  selected: _isSamePeriod(_period, _thisMonth()),
                  onTap: () => setState(() => _period = _thisMonth()),
                ),
                _PeriodPresetTile(
                  label: 'Minulý mesiac',
                  selected: _isSamePeriod(_period, _lastMonth()),
                  onTap: () => setState(() => _period = _lastMonth()),
                ),
                _PeriodPresetTile(
                  label: 'Tento štvrťrok',
                  selected: _isSamePeriod(_period, _thisQuarter()),
                  onTap: () => setState(() => _period = _thisQuarter()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          BizCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  st.progress.message,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                BizProgressList(items: items),
                const SizedBox(height: 12),
                BizPrimaryButton(
                  label: context.t(AppStr.createExport),
                  icon: Icons.archive,
                  isLoading: st.isRunning,
                  onPressed: st.isRunning
                      ? null
                      : () => ctrl.run(uid: widget.uid, period: _period),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (st.result != null) ...[
            BizCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t(AppStr.exportReady),
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                      st.result!.zipPath.isNotEmpty
                          ? st.result!.zipPath
                          : 'Súbor pripravený na zdieľanie/stiahnutie',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      FilledButton.icon(
                        onPressed: () async {
                          final res = st.result!;
                          XFile file;
                          if (res.zipBytes != null) {
                            file = XFile.fromData(
                              res.zipBytes!,
                              mimeType: 'application/zip',
                              name: 'bizagent_export.zip',
                            );
                          } else {
                            file = XFile(res.zipPath);
                          }
                          await Share.shareXFiles([file]);
                        },
                        icon: const Icon(Icons.share),
                        label: Text(context.t(AppStr.share)),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => ctrl.reset(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Nový export'),
                      ),
                    ],
                  ),
                  if (st.result!.hasMissing) ...[
                    const SizedBox(height: 12),
                    Text(context.t(AppStr.missingItemsTitle),
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 6),
                    Text(context.t(AppStr.missingItemsBody)),
                    const SizedBox(height: 8),
                    ...st.result!.missingItems.take(6).map((m) => Text('• $m')),
                    if (st.result!.missingItems.length > 6)
                      Text('• +${st.result!.missingItems.length - 6} ďalších…'),
                  ],
                ],
              ),
            ),
          ],
          if (st.error != null) ...[
            const SizedBox(height: 16),
            BizCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(context.t(AppStr.errorGeneric),
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  Text('${st.error}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            )
          ],
        ],
      ),
    );
  }

  bool _isSamePeriod(ExportPeriod a, ExportPeriod b) =>
      a.from.year == b.from.year &&
      a.from.month == b.from.month &&
      a.from.day == b.from.day &&
      a.to.year == b.to.year &&
      a.to.month == b.to.month &&
      a.to.day == b.to.day;
}

class _PeriodPresetTile extends StatelessWidget {
  const _PeriodPresetTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: selected
          ? const Icon(Icons.check_circle)
          : const Icon(Icons.circle_outlined),
      onTap: onTap,
    );
  }
}
