import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/mess_repository.dart';
import '../domain/mess_model.dart';

class MessState {
  final List<MessModel> messes;
  final MessModel? activeMess;
  final bool isLoading;
  final String? errorMessage;

  const MessState({
    this.messes = const [],
    this.activeMess,
    this.isLoading = false,
    this.errorMessage,
  });

  MessState copyWith({
    List<MessModel>? messes,
    MessModel? activeMess,
    bool? isLoading,
    String? errorMessage,
  }) {
    return MessState(
      messes: messes ?? this.messes,
      activeMess: activeMess ?? this.activeMess,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final messControllerProvider =
    NotifierProvider<MessController, MessState>(MessController.new);

class MessController extends Notifier<MessState> {
  MessRepository get _repo => ref.read(messRepositoryProvider);

  @override
  MessState build() {
    Future.microtask(() => loadMesses());
    return const MessState(isLoading: true);
  }

  Future<void> loadMesses() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await _repo.getMyMesses();
      state = state.copyWith(
        messes: list,
        activeMess: list.isNotEmpty ? list.first : null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  void selectMess(MessModel mess) {
    state = state.copyWith(activeMess: mess);
  }

  Future<bool> createMess(String name, String? address) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newMess = await _repo.createMess(name, address);
      final updatedList = [...state.messes, newMess];
      state = state.copyWith(
        messes: updatedList,
        activeMess: newMess,
        isLoading: false,
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

  Future<bool> joinMess(String inviteCode) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final joinedMess = await _repo.joinMess(inviteCode);
      final updatedList = [...state.messes, joinedMess];
      state = state.copyWith(
        messes: updatedList,
        activeMess: joinedMess,
        isLoading: false,
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