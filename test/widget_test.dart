import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:geosaurio/main.dart';
import 'package:geosaurio/services/lg_service.dart';

void main() {
  testWidgets('GeoSaurioApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<LgService>(
        create: (_) => LgService(),
        child: const GeoSaurioApp(),
      ),
    );

    await tester.pump(const Duration(seconds: 6));
    await tester.pump();

    expect(find.byType(GeoSaurioApp), findsOneWidget);
  });
}
