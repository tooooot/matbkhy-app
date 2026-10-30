/// بيانات تجريبية للنسخة الأولى حتى تُربط الخلفية.
const _imgs = ['chop', 'grill', 'fried', 'bread', 'pasta', 'salad', 'pancake', 'brunch'];

class Meal {
  final String id, title, chef, area, tag, desc;
  final int price, likes, comments;
  final int hue;
  String get img => 'assets/img/${_imgs[int.parse(id) % _imgs.length]}.jpg';
  const Meal(this.id, this.title, this.chef, this.area, this.tag, this.desc, this.price, this.likes, this.comments, this.hue);
}

const meals = <Meal>[
  Meal('1', 'فراخ مشوية على الفحم', 'أكلات هنية', 'مركز الطائف، الحي الخامس', 'مأكولات سورية', 'وصفة لذيذة تجهز مع الكبسة والخضار والفلفل الأخضر', 100, 500, 54, 20),
  Meal('2', 'كبسة لحم', 'مطبخ أم خالد', 'جدة، حي الصفا', 'مأكولات عربية', 'كبسة لحم بلدي بالمكسرات', 85, 320, 31, 35),
  Meal('3', 'منسف أردني', 'سفرة الشام', 'جدة، حي الروضة', 'مأكولات أردنية', 'منسف باللبن الجميد واللحم', 120, 210, 19, 50),
  Meal('4', 'ورق عنب', 'أكلات هنية', 'مركز الطائف، الحي الخامس', 'مأكولات سورية', 'ورق عنب محشي بالزيت', 48, 150, 12, 10),
];

const sections = <(String, int, String)>[('مأكولات عربية', 20, 'brunch'), ('مأكولات سورية', 20, 'fried'), ('مأكولات أردنية', 20, 'bread'), ('حلويات', 14, 'pancake'), ('مشروبات', 9, 'salad')];
