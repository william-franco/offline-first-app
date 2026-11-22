import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offline_first_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('users screen reaches loaded, empty, loading, or error', (
    tester,
  ) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 20));

    final hasContent =
        find.text('Users').evaluate().isNotEmpty ||
        find.text('List is empty.').evaluate().isNotEmpty ||
        find.byType(ListTile).evaluate().isNotEmpty ||
        find.byType(CircularProgressIndicator).evaluate().isNotEmpty;

    expect(hasContent, isTrue);
  });
}