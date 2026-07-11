import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/l10n.dart';
import '../../../core/services/soft_delete_service.dart';
import '../../auth/providers/auth_repository.dart';
import '../../../shared/utils/biz_snackbar.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> {
  final Map<String, List<Map<String, dynamic>>> _trashItems = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrashItems();
  }

  Future<void> _loadTrashItems() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final userId = user.id;

    final service = ref.read(softDeleteServiceProvider);
    _trashItems.clear();

    // Load items from all collections
    final collections = [
      SoftDeleteCollections.invoices,
      SoftDeleteCollections.bizBotConversations,
      SoftDeleteCollections.notepadItems,
    ];

    for (final collection in collections) {
      final items = await service.getTrashItems(collection, userId).first;
      if (items.isNotEmpty) {
        _trashItems[collection] = items;
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _restoreItem(String collection, String itemId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final userId = user.id;

    try {
      await ref.read(softDeleteServiceProvider).restoreItem(collection, userId, itemId);
      if (!mounted) return;
      BizSnackbar.showSuccess(context, context.t(AppStr.trashItemRestored));
      _loadTrashItems(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(
        context,
        context.t(AppStr.trashRestoreError, params: {'error': '$e'}),
      );
    }
  }

  Future<void> _permanentDeleteItem(String collection, String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t(AppStr.trashPermanentDeleteTitle)),
        content: Text(context.t(AppStr.trashPermanentDeleteBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t(AppStr.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t(AppStr.trashPermanentDeleteConfirm)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final userId = user.id;

    try {
      await ref.read(softDeleteServiceProvider).permanentDeleteItem(collection, userId, itemId);
      if (!mounted) return;
      BizSnackbar.showSuccess(context, context.t(AppStr.trashItemDeleted));
      _loadTrashItems(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(
        context,
        context.t(AppStr.trashDeleteError, params: {'error': '$e'}),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.t(AppStr.trashEmptyAllTitle)),
        content: Text(context.t(AppStr.trashEmptyAllBody)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.t(AppStr.cancel)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.t(AppStr.trashEmptyAllConfirm)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    final userId = user.id;

    setState(() => _isLoading = true);

    try {
      final collections = [
        SoftDeleteCollections.invoices,
        SoftDeleteCollections.bizBotConversations,
        SoftDeleteCollections.notepadItems,
      ];

      for (final collection in collections) {
        await ref.read(softDeleteServiceProvider).emptyTrash(collection, userId);
      }

      if (!mounted) return;
      BizSnackbar.showSuccess(context, context.t(AppStr.trashEmptied));
      _loadTrashItems();
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(
        context,
        context.t(AppStr.trashEmptyError, params: {'error': '$e'}),
      );
      setState(() => _isLoading = false);
    }
  }

  String _getItemTitle(
    BuildContext context,
    Map<String, dynamic> item,
    String collection,
  ) {
    final data = item['data'] as Map<String, dynamic>;

    switch (collection) {
      case SoftDeleteCollections.invoices:
        return context.t(AppStr.trashInvoiceItem, params: {
          'number': '${data['number'] ?? 'bez čísla'}',
          'client': '${data['clientName'] ?? 'bez klienta'}',
        });
      case SoftDeleteCollections.bizBotConversations:
        return data['title'] ?? context.t(AppStr.trashNoTitle);
      case SoftDeleteCollections.notepadItems:
        return data['title'] ?? context.t(AppStr.trashNoTitle);
      default:
        return context.t(AppStr.trashUnknownItem);
    }
  }

  String _getItemSubtitle(BuildContext context, Map<String, dynamic> item) {
    final data = item['data'] as Map<String, dynamic>;
    final deletedAt = data['deletedAt'];

    if (deletedAt == null) return '';

    DateTime deleteTime;
    if (deletedAt is DateTime) {
      deleteTime = deletedAt;
    } else {
      deleteTime = DateTime.parse(deletedAt);
    }

    final daysLeft = 7 - DateTime.now().difference(deleteTime).inDays;
    final timeStr = DateFormat('dd.MM.yyyy HH:mm', 'sk').format(deleteTime);

    if (daysLeft > 0) {
      return context.t(AppStr.trashDeletedSubtitle, params: {
        'time': timeStr,
        'days': '$daysLeft',
      });
    }
    return context.t(AppStr.trashDeletedLessThanDay, params: {'time': timeStr});
  }

  IconData _getItemIcon(String collection) {
    switch (collection) {
      case SoftDeleteCollections.invoices:
        return Icons.receipt_long;
      case SoftDeleteCollections.bizBotConversations:
        return Icons.chat_bubble_outline;
      case SoftDeleteCollections.notepadItems:
        return Icons.note_alt_outlined;
      default:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalItems = _trashItems.values.fold(0, (sum, items) => sum + items.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.t(AppStr.trashTitle, params: {'count': '$totalItems'})),
        actions: [
          if (totalItems > 0)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: context.t(AppStr.trashEmptyTooltip),
              onPressed: _emptyTrash,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : totalItems == 0
              ? _buildEmptyState()
              : _buildTrashList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.delete_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            context.t(AppStr.trashEmptyTitle),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            context.t(AppStr.trashEmptyBody),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTrashList() {
    return ListView(
      children: _trashItems.entries.map((entry) {
        final collection = entry.key;
        final items = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _getCollectionTitle(context, collection),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            ...items.map((item) => _buildTrashItem(item, collection)),
            const Divider(),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildTrashItem(Map<String, dynamic> item, String collection) {
    final itemId = item['id'] as String;

    return Dismissible(
      key: Key('${collection}_$itemId'),
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.restore, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          _restoreItem(collection, itemId);
        } else {
          _permanentDeleteItem(collection, itemId);
        }
      },
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            _getItemIcon(collection),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(_getItemTitle(context, item, collection)),
        subtitle: Text(_getItemSubtitle(context, item)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: context.t(AppStr.trashRestoreTooltip),
              onPressed: () => _restoreItem(collection, itemId),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: context.t(AppStr.trashPermanentDeleteTooltip),
              onPressed: () => _permanentDeleteItem(collection, itemId),
            ),
          ],
        ),
      ),
    );
  }

  String _getCollectionTitle(BuildContext context, String collection) {
    switch (collection) {
      case SoftDeleteCollections.invoices:
        return context.t(AppStr.trashCollectionInvoices);
      case SoftDeleteCollections.bizBotConversations:
        return context.t(AppStr.trashCollectionBizBot);
      case SoftDeleteCollections.notepadItems:
        return context.t(AppStr.trashCollectionNotepad);
      default:
        return context.t(AppStr.trashCollectionOther);
    }
  }
}
