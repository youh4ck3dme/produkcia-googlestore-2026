import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/ui/biz_theme.dart';
import '../../auth/providers/auth_repository.dart';

class WatchedCompaniesScreen extends ConsumerWidget {
  const WatchedCompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    if (authState == null || authState.isAnonymous) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sledované firmy')),
        body: const Center(child: Text('Pre prístup k monitoringu sa musíte prihlásiť.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Monitoring Firiem'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('O monitoringu'),
                  content: const Text(
                    'BizAgent automaticky sleduje zmeny v registri u firiem, ktoré si vyhľadáte. '
                    'Ak zistíme zmenu (názov, adresa, štatutár), pošleme vám notifikáciu.',
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Dobre')),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('watched_companies')
            .where('subscribedUsers', arrayContains: authState.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Chyba pri načítaní: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.visibility_off_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Zatiaľ nesledujete žiadne firmy'),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => context.push('/ai-tools/ico-lookup'),
                    child: const Text('VYHĽADAŤ FIRMU'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(BizTheme.spacingMd),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final ico = data['ico'] ?? '';
              
              // We need to fetch the snapshot data to get the name
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('company_snapshots').doc(ico).get(),
                builder: (context, snapshot) {
                  final name = (snapshot.data?.data() as Map<String, dynamic>?)?['name'] ?? 'IČO: $ico';
                  final status = (snapshot.data?.data() as Map<String, dynamic>?)?['status'] ?? 'active';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('IČO: $ico • ${status == 'active' ? 'Aktívna' : 'Neaktívna'}'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        // Navigate to IČO lookup with this IČO to see full details
                        context.push('/ai-tools/ico-lookup', extra: ico);
                      },
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
