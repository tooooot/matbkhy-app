import 'package:flutter/material.dart';
import '../api.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'orders.dart';

/// الحساب: الملف الشخصي مفصول عن الإعدادات؛ الأدوار الفعلية من النواة (مستخدم / طاهٍ / كابتن).
class AccountScreen extends StatefulWidget {
  final VoidCallback onSignedOut;
  const AccountScreen({super.key, required this.onSignedOut});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String role = 'user';

  List<(String, String)> get roles {
    final me = Api.me!;
    return [('user', 'مستخدم'), if (me.has('chef')) ('chef', 'طاهٍ'), if (me.has('captain')) ('captain', 'كابتن')];
  }

  Future<void> _request(String r) async {
    try {
      await Api.requestRole(r, '');
      if (mounted) toast(context, 'وصل طلبك، سيراجعه المدير');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = Api.me;
    if (me == null) return const Center(child: Text('تعذّر تحميل الحساب'));
    final rs = roles;
    if (!rs.any((r) => r.$1 == role)) role = 'user';
    return Scaffold(
      appBar: AppBar(title: const Text('حسابي'), actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _settings(context))]),
      body: ListView(children: [
        const SizedBox(height: 12),
        const Center(child: CircleAvatar(radius: 42, backgroundColor: C.field, child: Icon(Icons.person, size: 44))),
        const SizedBox(height: 8),
        Center(child: Text(me.name.isEmpty ? 'مستخدم مطبخي' : me.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
        Center(child: Text(me.email, style: const TextStyle(color: C.line, fontSize: 12))),
        const SizedBox(height: 16),
        if (rs.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: [for (final r in rs) ButtonSegment(value: r.$1, label: Text(r.$2))],
              selected: {role},
              onSelectionChanged: (s) => setState(() => role = s.first),
            ),
          ),
        const SizedBox(height: 12),
        if (role == 'chef')
          SizedBox(height: 520, child: Load<Order>(fetch: Api.chefOrders, empty: 'لا توجد طلبات جديدة', builder: (_, os) => OrderList(os, actions: _chefActions)))
        else if (role == 'captain')
          SizedBox(height: 520, child: Load<Order>(fetch: Api.captainOrders, empty: 'لا توجد توصيلات الآن', builder: (_, os) => OrderList(os, actions: _capActions)))
        else
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              if (!me.has('chef')) OutlinedButton(onPressed: () => _request('chef'), child: const Text('اطلب أن تصبح طاهياً وانشر وجباتك')),
              if (!me.has('captain')) OutlinedButton(onPressed: () => _request('captain'), child: const Text('اطلب أن تصبح كابتن توصيل')),
            ]),
          ),
      ]),
    );
  }

  List<(String, String)> _chefActions(Order o) => switch (o.status) { 'pending' => [('accepted', 'قبول'), ('rejected', 'رفض')], 'accepted' => [('ready', 'جاهز')], _ => [] };
  List<(String, String)> _capActions(Order o) => switch (o.status) { 'ready' => [('picked', 'استلام')], 'picked' => [('delivered', 'تم التسليم')], _ => [] };

  void _settings(BuildContext c) => showModalBottomSheet(
        context: c, backgroundColor: C.card,
        builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.delete_outline), title: const Text('حذف الحساب'),
            onTap: () async {
              final ok = await showDialog<bool>(
                context: c,
                builder: (d) => AlertDialog(
                  backgroundColor: C.card, title: const Text('حذف الحساب نهائياً؟'), content: const Text('لا يمكن التراجع عن الحذف.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('إلغاء')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('حذف', style: TextStyle(color: C.orange)))],
                ),
              );
              if (ok != true) return;
              await Api.deleteAccount();
              if (c.mounted) Navigator.of(c).pop();
              widget.onSignedOut();
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout), title: const Text('تسجيل الخروج'),
            onTap: () async {
              await Api.signOut();
              if (c.mounted) Navigator.of(c).pop();
              widget.onSignedOut();
            },
          ),
        ]),
      );
}
