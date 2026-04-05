import 'package:flutter_test/flutter_test.dart';
import 'package:zyromart/main.dart';

void main() {
  testWidgets('App launches and shows phone auth entry', (WidgetTester tester) async {
    await tester.pumpWidget(const ZyroMartApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Phone-verified quick commerce'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Store Owner'), findsOneWidget);
    expect(find.text('Delivery'), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });
}
