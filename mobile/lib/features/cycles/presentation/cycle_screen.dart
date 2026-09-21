import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'cycle_controller.dart';
import '../domain/cycle_model.dart';

class CycleScreen extends ConsumerWidget {
  const CycleScreen({super.key});

  void _showCreateCycleDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController(
      text: DateFormat('MMMM yyyy').format(DateTime.now()),
    );
    final startDateCtrl = TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(DateTime.now()),
    );
    final endDateCtrl = TextEditingController();
    String? localError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Start New Month Cycle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (localError != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      localError!,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Cycle Name (e.g. October 2026)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Start Date (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateCtrl,
                  decoration: const InputDecoration(
                    labelText: 'End Date (Optional, YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty || startDateCtrl.text.trim().isEmpty) {
                        setDialogState(() => localError = 'Name and Start Date are required');
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        localError = null;
                      });

                      final err = await ref.read(cycleControllerProvider.notifier).createCycle(
                            nameCtrl.text.trim(),
                            startDateCtrl.text.trim(),
                            endDateCtrl.text.trim().isEmpty ? null : endDateCtrl.text.trim(),
                          );

                      if (err == null) {
                        if (context.mounted) Navigator.pop(ctx);
                      } else {
                        setDialogState(() {
                          isSubmitting = false;
                          localError = err;
                        });
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Activate Cycle'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSettleDialog(BuildContext context, WidgetRef ref, MonthCycleModel cycle) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Settle & Close ${cycle.name}?'),
        content: const Text(
          'Settling this cycle will freeze daily meal entries and finalize all balances on the ledger.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(cycleControllerProvider.notifier).settleCurrentCycle(cycle.id);
            },
            child: const Text('Settle & Close'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ACTIVE':
        return Colors.teal;
      case 'LOCKED':
        return Colors.amber.shade700;
      case 'SETTLED':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cycleControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Month Cycles & Settlement'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(cycleControllerProvider.notifier).loadCycles(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCycleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Month Cycle'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (state.errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                if (state.successMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      state.successMessage!,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),

                if (state.activeCycle != null) ...[
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.teal.shade400, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                state.activeCycle!.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Chip(
                                label: Text(
                                  state.activeCycle!.status,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                backgroundColor: _getStatusColor(state.activeCycle!.status),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text('Started: ${state.activeCycle!.startDate}'),
                          if (state.activeCycle!.endDate != null)
                            Text('Ends: ${state.activeCycle!.endDate}'),
                          const SizedBox(height: 16),
                          if (state.activeCycle!.isActive)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.amber.shade900,
                              ),
                              onPressed: () => _confirmSettleDialog(
                                context,
                                ref,
                                state.activeCycle!,
                              ),
                              icon: const Icon(Icons.lock_clock),
                              label: const Text('Close & Settle This Cycle'),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                const Text(
                  'Cycle History',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                if (state.cycles.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'No month cycles found for this mess.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...state.cycles.map(
                    (cycle) => Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(cycle.status).withValues(alpha: 0.2),
                          child: Icon(
                            cycle.isActive ? Icons.lock_open : Icons.lock_outline,
                            color: _getStatusColor(cycle.status),
                          ),
                        ),
                        title: Text(
                          cycle.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${cycle.startDate} ${cycle.endDate != null ? "to ${cycle.endDate}" : ""}',
                        ),
                        trailing: Chip(
                          label: Text(
                            cycle.status,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}