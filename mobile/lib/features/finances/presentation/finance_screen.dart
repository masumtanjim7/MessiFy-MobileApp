import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'finance_controller.dart';

class FinanceScreen extends ConsumerWidget {
  const FinanceScreen({super.key});

  void _showDepositDialog(BuildContext context, WidgetRef ref) {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? localError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Member Deposit'),
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
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Amount (BDT)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Reference',
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
                      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (amt <= 0) {
                        setDialogState(() => localError = 'Enter a valid amount greater than 0');
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        localError = null;
                      });

                      final err = await ref
                          .read(financeControllerProvider.notifier)
                          .addDeposit(amt, dateStr, noteCtrl.text.trim());

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
                  : const Text('Record'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExpenseDialog(BuildContext context, WidgetRef ref) {
    final descCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final dateStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    String? localError;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Log Bazaar Expense'),
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
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Item / Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cost (BDT)',
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
                      final amt = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
                      if (descCtrl.text.trim().isEmpty || amt <= 0) {
                        setDialogState(() => localError = 'Enter description and a valid cost');
                        return;
                      }

                      setDialogState(() {
                        isSubmitting = true;
                        localError = null;
                      });

                      final err = await ref
                          .read(financeControllerProvider.notifier)
                          .addExpense(descCtrl.text.trim(), amt, dateStr);

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
                  : const Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final finState = ref.watch(financeControllerProvider);
    final sheet = finState.balanceSheet;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finances & Ledger'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Balance Sheet'),
              Tab(text: 'Expenses'),
              Tab(text: 'Deposits'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.read(financeControllerProvider.notifier).loadFinancialData(),
            )
          ],
        ),
        body: finState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              title: 'Meal Rate',
                              value: '৳ ${sheet?.mealRate.toStringAsFixed(2) ?? "0.00"}',
                              color: Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Expense',
                              value: '৳ ${sheet?.totalExpenses.toStringAsFixed(0) ?? "0"}',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _StatCard(
                              title: 'Total Meals',
                              value: (sheet?.totalMeals ?? 0.0).toStringAsFixed(1),
                              color: Colors.blueGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Member Ledger',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      if (sheet == null || sheet.memberRows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text('No active calculation data found for this cycle.'),
                          ),
                        )
                      else
                        ...sheet.memberRows.map(
                          (row) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text(
                                row.memberName,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                'Meals: ${row.totalMeals.toStringAsFixed(1)} | Cost: ৳${row.mealCost.toStringAsFixed(1)} | Paid: ৳${row.totalDeposits.toStringAsFixed(1)}',
                              ),
                              trailing: Text(
                                '${row.balance >= 0 ? "+" : ""}৳ ${row.balance.toStringAsFixed(1)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: row.balance >= 0 ? Colors.green : Colors.redAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  Scaffold(
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: () => _showExpenseDialog(context, ref),
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text('Add Expense'),
                    ),
                    body: finState.expenses.isEmpty
                        ? const Center(child: Text('No bazaar expenses recorded yet.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: finState.expenses.length,
                            itemBuilder: (ctx, i) {
                              final exp = finState.expenses[i];
                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.shopping_bag_outlined),
                                  ),
                                  title: Text(exp.description),
                                  subtitle: Text(exp.date),
                                  trailing: Text(
                                    '৳ ${exp.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  Scaffold(
                    floatingActionButton: FloatingActionButton.extended(
                      onPressed: () => _showDepositDialog(context, ref),
                      icon: const Icon(Icons.add_card),
                      label: const Text('Add Deposit'),
                    ),
                    body: finState.deposits.isEmpty
                        ? const Center(child: Text('No member deposits recorded yet.'))
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: finState.deposits.length,
                            itemBuilder: (ctx, i) {
                              final dep = finState.deposits[i];
                              return Card(
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    child: Icon(Icons.account_balance_wallet_outlined),
                                  ),
                                  title: Text(dep.userName),
                                  subtitle: Text(
                                    '${dep.date} ${dep.notes != null && dep.notes!.isNotEmpty ? "• ${dep.notes}" : ""}',
                                  ),
                                  trailing: Text(
                                    '৳ ${dep.amount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.15),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}