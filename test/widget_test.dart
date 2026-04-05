import 'package:flutter_test/flutter_test.dart';
import 'package:zyromart/main.dart';

void main() {
  testWidgets('App launches and shows role selection', (WidgetTester tester) async {
    await tester.pumpWidget(const ZyroMartApp());
    await tester.pumpAndSettle();

    expect(find.text('ZyroMart'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Store Owner'), findsOneWidget);
    expect(find.text('Delivery Partner'), findsOneWidget);
  });
}
