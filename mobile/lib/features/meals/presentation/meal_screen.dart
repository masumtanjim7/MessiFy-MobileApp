import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/presentation/auth_controller.dart';
import 'meal_controller.dart';

class MealScreen extends ConsumerStatefulWidget {
  const MealScreen({super.key});

  @override
  ConsumerState<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends ConsumerState<MealScreen> {
  double _breakfast = 0.0;
  double _lunch = 1.0;
  double _dinner = 1.0;

  Widget _buildMealCounter({
    required String title,
    required IconData icon,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.remove),
              onPressed: value > 0 ? () => onChanged(value - 0.5) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                value.toStringAsFixed(1),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton.filledTonal(
              icon: const Icon(Icons.add),
              onPressed: () => onChanged(value + 0.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealState = ref.watch(mealControllerProvider);
    final user = ref.watch(authControllerProvider).user;
    final formattedDate = DateFormat('EEEE, MMM d, yyyy').format(mealState.selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Meals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: mealState.selectedDate,
                firstDate: DateTime(2025),
                lastDate: DateTime(2030),
              );
              if (picked != null) {
                ref.read(mealControllerProvider.notifier).loadMealsForDate(picked);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Logging for: ${user?.fullName ?? "You"}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  Chip(
                    label: Text(
                      'Total: ${(_breakfast + _lunch + _dinner).toStringAsFixed(1)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (mealState.errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealState.errorMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            if (mealState.successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.teal.shade800,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  mealState.successMessage!,
                  style: const TextStyle(color: Colors.white),
                ),
              ),

            _buildMealCounter(
              title: 'Breakfast',
              icon: Icons.free_breakfast_outlined,
              value: _breakfast,
              onChanged: (v) => setState(() => _breakfast = v),
            ),
            const SizedBox(height: 8),
            _buildMealCounter(
              title: 'Lunch',
              icon: Icons.lunch_dining_outlined,
              value: _lunch,
              onChanged: (v) => setState(() => _lunch = v),
            ),
            const SizedBox(height: 8),
            _buildMealCounter(
              title: 'Dinner',
              icon: Icons.dinner_dining_outlined,
              value: _dinner,
              onChanged: (v) => setState(() => _dinner = v),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: mealState.isLoading
                  ? null
                  : () {
                      ref.read(mealControllerProvider.notifier).submitMeal(
                            breakfast: _breakfast,
                            lunch: _lunch,
                            dinner: _dinner,
                          );
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              icon: mealState.isLoading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Meals', style: TextStyle(fontSize: 16)),
            ),

            const SizedBox(height: 32),
            const Text(
              'Mess Daily Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (mealState.dailyMeals.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: Text(
                    'No recorded meals for this date yet.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              )
            else
              ...mealState.dailyMeals.map(
                (m) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(m.userName),
                    subtitle: Text(
                      'B: ${m.breakfast.toStringAsFixed(1)} | L: ${m.lunch.toStringAsFixed(1)} | D: ${m.dinner.toStringAsFixed(1)}',
                    ),
                    trailing: Chip(
                      label: Text(
                        '${m.totalMeals.toStringAsFixed(1)} meals',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}