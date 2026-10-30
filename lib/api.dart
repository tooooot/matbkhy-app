import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'data.dart';

const apiBase = 'https://matbkhy.wardyat.net';
const coreBase = 'https://core.wardyat.net';

/// مفتاح التطبيق في wardyat-core: مفتاح عام لعميل الجوال (يُحمَّل عند البناء)، لا يمنح صلاحية بلا جلسة.
const coreAppKey = String.fromEnvironment('CORE_APP_KEY');

class ApiError implements Exception {
  final int code;
  final String message;
  ApiError(this.code, this.message);
  @override
  String toString() => message;
}

class Me {
  final String id, name, email;
  final List<String> roles;
  Me.fromJson(Map<String, dynamic> j)
      : id = j['id'], name = j['name'] ?? '', email = j['email'] ?? '', roles = [for (final r in (j['roles'] as List? ?? [])) '$r'];
  bool has(String r) => roles.contains(r) || roles.contains('admin') || roles.contains('owner');
}

/// جلسة المستخدم (من wardyat-core) وطلبات الخلفية.
class Api {
  static String? token;
  static Me? me;
  static bool get signedIn => token != null;

  static Future<void> load() async {
    token = (await SharedPreferences.getInstance()).getString('token');
    if (token != null) {
      try {
        await refreshMe();
      } on ApiError catch (e) {
        if (e.code == 401) await signOut();
      } catch (_) {}
    }
  }

  static Future<void> refreshMe() async => me = Me.fromJson((await _call('GET', '$coreBase/v1/me', core: true))['user']);

  static Future<Map<String, dynamic>> publicConfig() => _call('GET', '$coreBase/v1/public-config', core: true);

  /// provider: google | apple.
  static Future<void> socialLogin(String provider, String idToken) async {
    final r = await _call('POST', '$coreBase/v1/auth/$provider', core: true, body: {'id_token': idToken});
    token = r['token'];
    await (await SharedPreferences.getInstance()).setString('token', token!);
    me = Me.fromJson(r['user']);
  }

  static Future<void> signOut() async {
    try {
      if (token != null) await _call('POST', '$coreBase/v1/auth/logout', core: true);
    } catch (_) {}
    token = null;
    me = null;
    await (await SharedPreferences.getInstance()).remove('token');
  }

  static Future<void> deleteAccount() async {
    await _call('DELETE', '$coreBase/v1/me', core: true);
    token = null;
    me = null;
    await (await SharedPreferences.getInstance()).remove('token');
  }

  static Future<List<SectionInfo>> sections() async =>
      [for (final s in await _list('/v1/sections')) SectionInfo(s['name'], s['count'])];

  static Future<List<Meal>> meals({String? section, String? q, String? chef}) async {
    final qs = {if (section != null) 'section': section, if (q != null && q.isNotEmpty) 'q': q, if (chef != null) 'chef': chef};
    return [for (final m in await _list('/v1/meals', qs)) Meal.fromJson(m)];
  }

  static Future<Map<String, dynamic>> like(String mealId) => _call('POST', '$apiBase/v1/meals/$mealId/like');

  static Future<List<String>> placeOrder(List<(String, int)> items, String address) async {
    final r = await _call('POST', '$apiBase/v1/orders', body: {'items': [for (final i in items) {'meal_id': i.$1, 'qty': i.$2}], 'address': address});
    return [for (final o in r['orders']) '$o'];
  }

  static Future<List<Order>> myOrders() async => [for (final o in await _list('/v1/orders/mine')) Order.fromJson(o)];
  static Future<List<Order>> chefOrders() async => [for (final o in await _list('/v1/chef/orders')) Order.fromJson(o)];
  static Future<List<Order>> captainOrders() async => [for (final o in await _list('/v1/captain/orders')) Order.fromJson(o)];
  static Future<void> setStatus(String orderId, String status) => _call('POST', '$apiBase/v1/orders/$orderId/status', body: {'status': status});
  static Future<void> requestRole(String role, String info) => _call('POST', '$apiBase/v1/role-requests', body: {'role': role, 'info': info});

  static Future<List<dynamic>> _list(String path, [Map<String, String>? qs]) async {
    final r = await _send('GET', Uri.parse('$apiBase$path').replace(queryParameters: qs));
    return r as List<dynamic>;
  }

  static Future<Map<String, dynamic>> _call(String method, String url, {Map<String, dynamic>? body, bool core = false}) async =>
      (await _send(method, Uri.parse(url), body: body, core: core)) as Map<String, dynamic>;

  static Future<dynamic> _send(String method, Uri url, {Map<String, dynamic>? body, bool core = true}) async {
    final h = {'Content-Type': 'application/json', if (token != null) 'Authorization': 'Bearer $token', if (url.host == Uri.parse(coreBase).host) 'X-App-Key': coreAppKey};
    final req = http.Request(method, url)..headers.addAll(h);
    if (body != null) req.body = jsonEncode(body);
    final res = await http.Response.fromStream(await req.send().timeout(const Duration(seconds: 20)));
    final j = res.body.isEmpty ? {} : jsonDecode(utf8.decode(res.bodyBytes));
    if (res.statusCode >= 400) throw ApiError(res.statusCode, (j is Map ? j['error'] : null) ?? 'خطأ ${res.statusCode}');
    return j;
  }
}
