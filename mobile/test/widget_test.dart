import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:messify_app/main.dart';

void main() {
  testWidgets('Messify app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MessifyApp(),
      ),
    );

    expect(find.byType(MessifyApp), findsOneWidget);
  });
}