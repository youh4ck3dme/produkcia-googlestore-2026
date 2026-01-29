import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BizCurrencyInput extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const BizCurrencyInput({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}')),
      ],
      decoration: InputDecoration(
        labelText: label,
        suffixText: '€',
        errorText: errorText,
      ),
      onChanged: onChanged,
    );
  }
}
