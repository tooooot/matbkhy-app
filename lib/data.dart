/// نماذج البيانات القادمة من خلفية مطبخي.
const _imgs = ['chop', 'grill', 'fried', 'bread', 'pasta', 'salad', 'pancake', 'brunch'];

class Meal {
  final String id, title, chef, chefId, area, section, desc;
  final String? video;
  final int price, qty, likes, comments;
  Meal.fromJson(Map<String, dynamic> j)
      : id = j['id'], title = j['title'], chef = j['chef'] ?? '', chefId = j['chef_id'] ?? '', area = j['area'] ?? '',
        section = j['section'] ?? '', desc = j['desc'] ?? '', video = j['video'], price = j['price'], qty = j['qty'],
        likes = j['likes'] ?? 0, comments = j['comments'] ?? 0;

  /// صورة بديلة محلية إلى أن تُرفع صورة مصغّرة للوجبة.
  String get img => 'assets/img/${_imgs[id.hashCode.abs() % _imgs.length]}.jpg';
}

class OrderItem {
  final String title;
  final int price, qty;
  OrderItem.fromJson(Map<String, dynamic> j) : title = j['title'], price = j['price'], qty = j['qty'];
}

class Order {
  final String id, status, address, created;
  final int total;
  final List<OrderItem> items;
  Order.fromJson(Map<String, dynamic> j)
      : id = j['id'], status = j['status'], address = j['address'] ?? '', created = j['created'] ?? '', total = j['total'],
        items = [for (final i in (j['items'] as List)) OrderItem.fromJson(i)];

  String get statusAr => const {
        'pending': 'بانتظار الطاهي', 'accepted': 'قيد التحضير', 'ready': 'جاهز للتوصيل', 'picked': 'في الطريق',
        'delivered': 'تم التسليم', 'rejected': 'رفضه الطاهي', 'cancelled': 'ملغي',
      }[status] ?? status;
  bool get open => !['delivered', 'rejected', 'cancelled'].contains(status);
}

class SectionInfo {
  final String name;
  final int count;
  SectionInfo(this.name, this.count);
}

const sectionImages = {'مأكولات عربية': 'brunch', 'مأكولات سورية': 'fried', 'مأكولات أردنية': 'bread', 'حلويات': 'pancake', 'مشروبات': 'salad'};
