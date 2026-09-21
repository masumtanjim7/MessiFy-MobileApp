import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../finances/presentation/finance_screen.dart';
import '../../meals/presentation/meal_screen.dart';
import 'mess_controller.dart';

class MessSelectionScreen extends ConsumerWidget {
  const MessSelectionScreen({super.key});

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create New Mess'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Mess Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(
                labelText: 'Address (Optional)',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final ok = await ref.read(messControllerProvider.notifier).createMess(
                    nameCtrl.text.trim(),
                    addressCtrl.text.trim(),
                  );
              if (ok && context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showJoinDialog(BuildContext context, WidgetRef ref) {
    final codeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Mess with Invite Code'),
        content: TextField(
          controller: codeCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: '6-character Code (e.g. A9B2X1)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (codeCtrl.text.trim().isEmpty) return;
              final ok = await ref
                  .read(messControllerProvider.notifier)
                  .joinMess(codeCtrl.text.trim());
              if (ok && context.mounted) Navigator.pop(ctx);
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messState = ref.watch(messControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Text(
          messState.activeMess?.name ?? 'Select Mess',
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(messControllerProvider.notifier).loadMesses(),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: messState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (messState.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    color: Colors.red.shade900,
                    child: Text(
                      'Error: ${messState.errorMessage!}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                Expanded(
                  child: messState.messes.isEmpty
                      ? Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.holiday_village_outlined,
                                  size: 72,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Welcome, ${user?.fullName ?? ""}!',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'You are not a member of any mess yet. Create one or join an existing mess using an invite code.',
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                FilledButton.icon(
                                  onPressed: () => _showCreateDialog(context, ref),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create a Mess'),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () => _showJoinDialog(context, ref),
                                  icon: const Icon(Icons.group_add),
                                  label: const Text('Join with Code'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Card(
                              elevation: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Active Mess: ${messState.activeMess?.name}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text('Invite Code: ${messState.activeMess?.inviteCode}'),
                                    if (messState.activeMess?.address != null &&
                                        messState.activeMess!.address!.isNotEmpty)
                                      Text('Address: ${messState.activeMess!.address}'),
                                    const SizedBox(height: 16),
                                    Wrap(
                                      spacing: 10,
                                      runSpacing: 10,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const MealScreen(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.restaurant_menu),
                                          label: const Text('Open Meal Manager'),
                                        ),
                                        FilledButton.tonalIcon(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => const FinanceScreen(),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.account_balance_wallet_outlined),
                                          label: const Text('Open Finances & Ledger'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Your Messes',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...messState.messes.map(
                              (m) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const Icon(Icons.apartment),
                                  title: Text(m.name),
                                  subtitle: Text('Invite Code: ${m.inviteCode}'),
                                  trailing: messState.activeMess?.id == m.id
                                      ? const Icon(Icons.check_circle, color: Colors.teal)
                                      : null,
                                  onTap: () => ref
                                      .read(messControllerProvider.notifier)
                                      .selectMess(m),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showCreateDialog(context, ref),
                                    icon: const Icon(Icons.add),
                                    label: const Text('New Mess'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _showJoinDialog(context, ref),
                                    icon: const Icon(Icons.group_add),
                                    label: const Text('Join Mess'),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
    );
  }
}