import 'package:flutter_test/flutter_test.dart';
import 'package:geosaurio/main.dart';

void main() {
  testWidgets('GeoSaurioApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoSaurioApp());

    await tester.pumpAndSettle(const Duration(seconds: 6));

    expect(find.byType(GeoSaurioApp), findsOneWidget);
  });
}
