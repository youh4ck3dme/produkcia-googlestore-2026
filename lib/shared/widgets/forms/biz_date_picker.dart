import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/ui/biz_theme.dart';

class BizDatePicker extends StatelessWidget {
  final String label;
  final DateTime? selectedDate;
  final ValueChanged<DateTime> onDateSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const BizDatePicker({
    super.key,
    required this.label,
    required this.selectedDate,
    required this.onDateSelected,
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textController = TextEditingController(
      text: selectedDate != null ? DateFormat('dd.MM.yyyy').format(selectedDate!) : '',
    );

    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: selectedDate ?? DateTime.now(),
          firstDate: firstDate ?? DateTime(2020),
          lastDate: lastDate ?? DateTime(2030),
          builder: (context, child) {
            return Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(
                  primary: BizTheme.slovakBlue, // Ensure brand color in picker
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );
        if (date != null) {
          onDateSelected(date);
        }
      },
      child: IgnorePointer(
        child: TextFormField(
          controller: textController,
          decoration: InputDecoration(
            labelText: label,
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
