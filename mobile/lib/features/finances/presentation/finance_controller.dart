import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../messes/presentation/mess_controller.dart';
import '../data/finance_repository.dart';
import '../domain/finance_models.dart';

class FinanceState {
  final MonthCycleModel? activeCycle;
  final BalanceSheetModel? balanceSheet;
  final List<DepositModel> deposits;
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final String? errorMessage;

  const FinanceState({
    this.activeCycle,
    this.balanceSheet,
    this.deposits = const [],
    this.expenses = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  FinanceState copyWith({
    MonthCycleModel? activeCycle,
    BalanceSheetModel? balanceSheet,
    List<DepositModel>? deposits,
    List<ExpenseModel>? expenses,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FinanceState(
      activeCycle: activeCycle ?? this.activeCycle,
      balanceSheet: balanceSheet ?? this.balanceSheet,
      deposits: deposits ?? this.deposits,
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final financeControllerProvider =
    NotifierProvider<FinanceController, FinanceState>(FinanceController.new);

class FinanceController extends Notifier<FinanceState> {
  FinanceRepository get _repo => ref.read(financeRepositoryProvider);

  @override
  FinanceState build() {
    Future.microtask(() => loadFinancialData());
    return const FinanceState(isLoading: true);
  }

  Future<void> loadFinancialData() async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final cycle = await _repo.getActiveCycle(activeMess.id);
      BalanceSheetModel? sheet;
      if (cycle != null) {
        sheet = await _repo.getBalanceSheet(activeMess.id, cycle.id);
      }

      final deposits = await _repo.getDeposits(activeMess.id);
      final expenses = await _repo.getExpenses(activeMess.id);

      state = FinanceState(
        activeCycle: cycle,
        balanceSheet: sheet,
        deposits: deposits,
        expenses: expenses,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<String?> addDeposit(double amount, String date, String? notes) async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return 'No active mess selected';

    if (state.activeCycle == null) {
      await loadFinancialData();
    }

    final cycleId = state.activeCycle?.id;
    if (cycleId == null) {
      return 'No active month cycle found for this mess. Please create one in Admin.';
    }

    try {
      await _repo.logDeposit(
        messId: activeMess.id,
        amount: amount,
        date: date,
        notes: notes,
        cycleId: cycleId,
      );
      await loadFinancialData();
      return null;
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: error);
      return error;
    }
  }

  Future<String?> addExpense(String description, double amount, String date) async {
    final activeMess = ref.read(messControllerProvider).activeMess;
    if (activeMess == null) return 'No active mess selected';

    if (state.activeCycle == null) {
      await loadFinancialData();
    }

    final cycleId = state.activeCycle?.id;
    if (cycleId == null) {
      return 'No active month cycle found for this mess. Please create one in Admin.';
    }

    try {
      await _repo.logExpense(
        messId: activeMess.id,
        description: description,
        amount: amount,
        date: date,
        cycleId: cycleId,
      );
      await loadFinancialData();
      return null;
    } catch (e) {
      final error = e.toString().replaceFirst('Exception: ', '');
      state = state.copyWith(errorMessage: error);
      return error;
    }
  }
}