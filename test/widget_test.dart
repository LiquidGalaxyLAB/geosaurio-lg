import 'package:flutter_test/flutter_test.dart';
import 'package:geosaurio/main.dart';

void main() {
  testWidgets('GeoSaurioApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const GeoSaurioApp());

    // Verify that the app starts (checks for a title or main widget)
    expect(find.byType(GeoSaurioApp), findsOneWidget);
  });
}
