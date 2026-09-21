import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../messes/presentation/mess_controller.dart';
import '../data/cycle_repository.dart';
import '../domain/cycle_model.dart';

class CycleState {
  final List<MonthCycleModel> cycles;
  final MonthCycleModel? activeCycle;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const CycleState({
    this.cycles = const [],
    this.activeCycle,
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  CycleState copyWith({
    List<MonthCycleModel>? cycles,
    MonthCycleModel? activeCycle,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return CycleState(
      cycles: cycles ?? this.cycles,
      activeCycle: activeCycle ?? this.activeCycle,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final cycleControllerProvider =
    NotifierProvider<CycleController, CycleState>(CycleController.new);

class CycleController extends Notifier<CycleState> {
  CycleRepository get _repo => ref.read(cycleRepositoryProvider);

  @override
  CycleState build() {
    Future.microtask(() => loadCycles());
    return const CycleState(isLoading: true);
  }

  Future<void> loadCycles() async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);

    try {
      final list = await _repo.getCycles(activeMess.id);
      MonthCycleModel? currentActive;

      try {
        currentActive = list.firstWhere((c) => c.isActive);
      } catch (_) {
        currentActive = list.isNotEmpty ? list.first : null;
      }

      state = CycleState(
        cycles: list,
        activeCycle: currentActive,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String?> createCycle(String name, String startDate, String? endDate) async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return 'No active mess selected';

    try {
      await _repo.createCycle(
        messId: activeMess.id,
        name: name,
        startDate: startDate,
        endDate: endDate,
      );
      await loadCycles();
      state = state.copyWith(successMessage: 'New month cycle activated successfully!');
      return null;
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: error);
      return error;
    }
  }

  Future<String?> settleCurrentCycle(int cycleId) async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return 'No active mess selected';

    try {
      await _repo.settleCycle(activeMess.id, cycleId);
      await loadCycles();
      state = state.copyWith(successMessage: 'Cycle settled and closed successfully!');
      return null;
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: error);
      return error;
    }
  }
}