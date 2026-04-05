import 'package:flutter_test/flutter_test.dart';
import 'package:zyromart/main.dart';

void main() {
  testWidgets('App launches and shows intro onboarding', (WidgetTester tester) async {
    await tester.pumpWidget(const ZyroMartApp());
    await tester.pumpAndSettle();

    expect(find.textContaining('Groceries, operations, and delivery'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Built for daily operations'), findsOneWidget);
  });
}
