import 'package:flutter_test/flutter_test.dart';
import 'package:zyromart/main.dart';

void main() {
  testWidgets('App launches and shows animated splash', (WidgetTester tester) async {
    await tester.pumpWidget(const ZyroMartApp());
    await tester.pump();

    expect(find.text('ZyroMart'), findsOneWidget);
    expect(find.text('Everyday delivery, storefront, and rider operations'), findsOneWidget);
  });
}
