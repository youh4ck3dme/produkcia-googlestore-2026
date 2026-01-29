import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/ui/biz_theme.dart';
import '../../features/tools/services/monitoring_service.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitoring = ref.watch(monitoringServiceProvider);
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: monitoring.notifications(),
      builder: (_, snap) {
        final items = snap.data ?? [];
        final unread = items.where((n) => n['read'] == false).length;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              onPressed: () {
                _showNotificationsSheet(context, items, ref);
              },
              icon: const Icon(Icons.notifications_outlined),
            ),
            if (unread > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: BizTheme.nationalRed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    unread > 9 ? '9+' : '$unread',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
          ],
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context, List<Map<String, dynamic>> items, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _NotificationsSheet(items: items),
    );
  }
}

class _NotificationsSheet extends ConsumerWidget {
  final List<Map<String, dynamic>> items;

  const _NotificationsSheet({required this.items});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(BizTheme.radiusXl)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(BizTheme.spacingLg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifikácie',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    ref.read(monitoringServiceProvider).markAllAsRead();
                  },
                  child: const Text('Označiť všetko ako prečítané'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
             Expanded(
               child: Center(
                 child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                     Icon(Icons.notifications_off_outlined, size: 48, color: theme.disabledColor),
                     const SizedBox(height: 16),
                     Text('Žiadne nové notifikácie', style: theme.textTheme.bodyLarge?.copyWith(color: theme.disabledColor)),
                   ],
                 ),
               ),
             )
          else
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, index) {
                  final item = items[index];
                  final isRead = item['read'] == true;
                  final timestamp = item['createdAt'];
                  final date = timestamp is Timestamp ? timestamp.toDate() : null;
                  
                  return ListTile(
                    tileColor: isRead ? null : theme.colorScheme.primary.withValues(alpha: 0.05),
                    leading: CircleAvatar(
                      backgroundColor: isRead ? theme.disabledColor.withValues(alpha: 0.1) : theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.business, 
                        color: isRead ? theme.disabledColor : theme.colorScheme.primary,
                        size: 20
                      ),
                    ),
                    title: Text(
                      item['title'] ?? 'Upozornenie',
                      style: TextStyle(
                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(item['body'] ?? ''),
                        if (date != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(date),
                            style: theme.textTheme.labelSmall?.copyWith(color: theme.disabledColor),
                          ),
                        ]
                      ],
                    ),
                    onTap: () {
                       ref.read(monitoringServiceProvider).markAsRead(item['id']);
                       // Could navigate to details here
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple formatter, ideally use intl
    return '${date.day}.${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
