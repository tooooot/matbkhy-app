import 'package:flutter_test/flutter_test.dart';
import 'package:matbkhy/main.dart';
import 'package:matbkhy/data.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('بلا جلسة يفتح التطبيق على شاشة الدخول', (t) async {
    SharedPreferences.setMockInitialValues({});
    await t.pumpWidget(const MatbkhyApp());
    await t.pumpAndSettle();
    expect(find.text('مرحباً بك في مطبخي'), findsOneWidget);
  });

  test('نموذج الوجبة والطلب يقرأان استجابة الخلفية', () {
    final m = Meal.fromJson({'id': 'a1', 'title': 'كبسة', 'section': 'مأكولات عربية', 'price': 85, 'qty': 3, 'chef_id': 'c1', 'video': null});
    expect(m.price, 85);
    expect(m.img, startsWith('assets/img/'));
    final o = Order.fromJson({'id': 'o1', 'status': 'ready', 'total': 85, 'address': 'جدة', 'items': [{'title': 'كبسة', 'price': 85, 'qty': 1}]});
    expect(o.statusAr, 'جاهز للتوصيل');
    expect(o.open, isTrue);
  });
}
