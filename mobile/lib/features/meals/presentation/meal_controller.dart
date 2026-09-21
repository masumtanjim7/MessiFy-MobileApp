import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../messes/presentation/mess_controller.dart';
import '../data/meal_repository.dart';
import '../domain/meal_model.dart';

class MealState {
  final DateTime selectedDate;
  final List<MealModel> dailyMeals;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const MealState({
    required this.selectedDate,
    this.dailyMeals = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  MealState copyWith({
    DateTime? selectedDate,
    List<MealModel>? dailyMeals,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return MealState(
      selectedDate: selectedDate ?? this.selectedDate,
      dailyMeals: dailyMeals ?? this.dailyMeals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final mealControllerProvider =
    NotifierProvider<MealController, MealState>(MealController.new);

class MealController extends Notifier<MealState> {
  MealRepository get _repo => ref.read(mealRepositoryProvider);

  @override
  MealState build() {
    final now = DateTime.now();
    Future.microtask(() => loadMealsForDate(now));
    return MealState(selectedDate: now, isLoading: true);
  }

  String _formatDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> loadMealsForDate(DateTime date) async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return;

    state = state.copyWith(
      selectedDate: date,
      isLoading: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      final meals = await _repo.getMeals(
        messId: activeMess.id,
        date: _formatDate(date),
      );
      state = state.copyWith(dailyMeals: meals, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<bool> submitMeal({
    required double breakfast,
    required double lunch,
    required double dinner,
  }) async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    try {
      await _repo.logMeal(
        messId: activeMess.id,
        date: _formatDate(state.selectedDate),
        breakfast: breakfast,
        lunch: lunch,
        dinner: dinner,
      );

      await loadMealsForDate(state.selectedDate);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Meal updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}