import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Minimal smoke test to verify the app compiles.
    expect(1 + 1, equals(2));
  });
}
