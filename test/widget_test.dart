import 'package:beerer/app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    setupFirebaseCoreMocks();
    try {
      await Firebase.initializeApp();
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app') rethrow;
    }
  });

  testWidgets('BeerErApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BeerErApp()));
    // App renders without throwing.
    expect(find.byType(ProviderScope), findsOneWidget);

    // Advance past splash screen timer so no pending timers remain.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
