import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matbkhy/main.dart';

void main() {
  testWidgets('يفتح التطبيق على شاشة الدخول', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const MatbkhyApp());
    await t.pumpAndSettle();
    expect(find.text('مرحباً بك في مطبخي'), findsOneWidget);
  });
}
