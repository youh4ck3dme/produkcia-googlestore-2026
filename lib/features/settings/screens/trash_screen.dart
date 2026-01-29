import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    final user = ref.read(authStateProvider).valueOrNull;
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
    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final userId = user.id;

    try {
      await ref.read(softDeleteServiceProvider).restoreItem(collection, userId, itemId);
      if (!mounted) return;
      BizSnackbar.showSuccess(context, 'Položka bola obnovená');
      _loadTrashItems(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(context, 'Chyba pri obnovovaní: $e');
    }
  }

  Future<void> _permanentDeleteItem(String collection, String itemId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nenávratne vymazať?'),
        content: const Text('Táto akcia sa nedá vrátiť späť. Položka bude natrvalo vymazaná.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vymazať natrvalo'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(authStateProvider).valueOrNull;
    if (user == null) return;
    final userId = user.id;

    try {
      await ref.read(softDeleteServiceProvider).permanentDeleteItem(collection, userId, itemId);
      if (!mounted) return;
      BizSnackbar.showSuccess(context, 'Položka bola natrvalo vymazaná');
      _loadTrashItems(); // Refresh list
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(context, 'Chyba pri mazaní: $e');
    }
  }

  Future<void> _emptyTrash() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vyprázdniť kôš?'),
        content: const Text('Všetky položky v koši budú natrvalo vymazané. Túto akciu nie je možné vrátiť späť.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Zrušiť'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Vyprázdniť kôš'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final user = ref.read(authStateProvider).valueOrNull;
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
      BizSnackbar.showSuccess(context, 'Kôš bol vyprázdnený');
      _loadTrashItems();
    } catch (e) {
      if (!mounted) return;
      BizSnackbar.showError(context, 'Chyba pri vyprázdňovaní koša: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getItemTitle(Map<String, dynamic> item, String collection) {
    final data = item['data'] as Map<String, dynamic>;

    switch (collection) {
      case SoftDeleteCollections.invoices:
        return 'Faktúra ${data['number'] ?? 'bez čísla'} - ${data['clientName'] ?? 'bez klienta'}';
      case SoftDeleteCollections.bizBotConversations:
        return data['title'] ?? 'Bez názvu';
      case SoftDeleteCollections.notepadItems:
        return data['title'] ?? 'Bez názvu';
      default:
        return 'Neznáma položka';
    }
  }

  String _getItemSubtitle(Map<String, dynamic> item, String collection) {
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

    return 'Vymazané $timeStr • ${daysLeft > 0 ? '$daysLeft dní' : 'menej ako 1 deň'} na obnovenie';
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
        title: Text('Kôš ($totalItems)'),
        actions: [
          if (totalItems > 0)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Vyprázdniť kôš',
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
            'Kôš je prázdny',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Zmazané položky sa zobrazia tu na 7 dní',
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
                _getCollectionTitle(collection),
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
        title: Text(_getItemTitle(item, collection)),
        subtitle: Text(_getItemSubtitle(item, collection)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.restore),
              tooltip: 'Obnoviť',
              onPressed: () => _restoreItem(collection, itemId),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever),
              tooltip: 'Vymazať natrvalo',
              onPressed: () => _permanentDeleteItem(collection, itemId),
            ),
          ],
        ),
      ),
    );
  }

  String _getCollectionTitle(String collection) {
    switch (collection) {
      case SoftDeleteCollections.invoices:
        return 'Faktúry';
      case SoftDeleteCollections.bizBotConversations:
        return 'Rozhovory s BizBot';
      case SoftDeleteCollections.notepadItems:
        return 'Poznámky a bloky';
      default:
        return 'Iné položky';
    }
  }
}
