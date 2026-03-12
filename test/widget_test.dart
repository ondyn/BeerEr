import 'package:beerer/app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BeerErApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BeerErApp()));
    // App renders without throwing.
    expect(find.byType(ProviderScope), findsOneWidget);

    // Advance past splash screen timer so no pending timers remain.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
