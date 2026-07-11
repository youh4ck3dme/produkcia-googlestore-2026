import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bizagent/features/ai_tools/providers/ai_email_service.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/ui/biz_theme.dart';

class AiEmailGeneratorScreen extends ConsumerStatefulWidget {
  final String? initialType;
  final String? initialContext;

  const AiEmailGeneratorScreen({
    super.key,
    this.initialType,
    this.initialContext,
  });

  @override
  ConsumerState<AiEmailGeneratorScreen> createState() =>
      _AiEmailGeneratorScreenState();
}

class _AiEmailGeneratorScreenState
    extends ConsumerState<AiEmailGeneratorScreen> {
  late final TextEditingController _contextController;
  String _generatedEmail = '';
  bool _isLoading = false;

  late String _selectedType;
  String _selectedTone = 'formal';

  static const _typeKeys = {
    'reminder': AppStr.aiEmailTypeReminder,
    'quote': AppStr.aiEmailTypeQuote,
    'intro': AppStr.aiEmailTypeIntro,
  };

  static const _toneKeys = {
    'formal': AppStr.aiEmailToneFormal,
    'friendly': AppStr.aiEmailToneFriendly,
    'urgent': AppStr.aiEmailToneUrgent,
  };

  @override
  void initState() {
    super.initState();
    _contextController =
        TextEditingController(text: widget.initialContext ?? '');
    _selectedType = widget.initialType ?? 'reminder';
  }

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _saveAsTemplate() async {
    if (_generatedEmail.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.t(AppStr.aiEmailSavedTemplate))),
    );
  }

  Future<void> _generate() async {
    setState(() {
      _isLoading = true;
      _generatedEmail = '';
    });

    final service = ref.read(aiEmailServiceProvider);
    final result = await service.generateEmail(
      type: _selectedType,
      tone: _selectedTone,
      context: _contextController.text,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _generatedEmail = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.t(AppStr.aiEmailTitle))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: context.t(AppStr.aiEmailTypeLabel),
                        border: const OutlineInputBorder(),
                      ),
                      items: _typeKeys.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(context.t(e.value)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedTone,
                      decoration: InputDecoration(
                        labelText: context.t(AppStr.aiEmailToneLabel),
                        border: const OutlineInputBorder(),
                      ),
                      items: _toneKeys.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(context.t(e.value)),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedTone = v!),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _contextController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: context.t(AppStr.aiEmailContextLabel),
                        hintText: context.t(AppStr.aiEmailContextHint),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _generate,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: Text(context.t(AppStr.aiEmailGenerate)),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_generatedEmail.isNotEmpty)
              Card(
                color: BizTheme.gray50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.t(AppStr.aiEmailResult),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: () {
                              Clipboard.setData(
                                  ClipboardData(text: _generatedEmail));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(context.t(AppStr.copyToClipboard)),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const Divider(),
                      SelectableText(_generatedEmail),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _saveAsTemplate,
                          icon: const Icon(Icons.bookmark_border),
                          label: Text(context.t(AppStr.aiEmailSaveTemplate)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}