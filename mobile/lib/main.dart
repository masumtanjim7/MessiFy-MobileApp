import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/messes/presentation/mess_selection_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: MessifyApp(),
    ),
  );
}

class MessifyApp extends ConsumerWidget {
  const MessifyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'Messify',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F766E),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D9488),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: authState.isLoading && authState.status == AuthStatus.initial
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : authState.status == AuthStatus.authenticated
              ? const MessSelectionScreen()
              : const LoginScreen(),
    );
  }
}