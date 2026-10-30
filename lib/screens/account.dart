import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data.dart';
import '../theme.dart';

/// الحساب: الملف الشخصي (بيانات) مفصول عن الإعدادات؛ وتبديل الدور مستخدم / طاهٍ / كابتن.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});
  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String role = 'مستخدم';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('حسابي'),
          actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => _settings(context))],
        ),
        body: ListView(children: [
          const SizedBox(height: 12),
          const Center(child: CircleAvatar(radius: 42, backgroundColor: C.field, child: Icon(Icons.person, size: 44))),
          const SizedBox(height: 8),
          Center(child: Text('فاطمة محمد', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
          const Center(child: Text('@fyf865564bgjhj', style: TextStyle(color: C.line, fontSize: 12))),
          const SizedBox(height: 16),
          const Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [_Stat('8700', 'إعجاب'), _Stat('5000', 'متابع'), _Stat('505k', 'يتابع')]),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<String>(
              segments: const [ButtonSegment(value: 'مستخدم', label: Text('مستخدم')), ButtonSegment(value: 'طاهٍ', label: Text('طاهٍ')), ButtonSegment(value: 'كابتن', label: Text('كابتن'))],
              selected: {role},
              onSelectionChanged: (s) => setState(() => role = s.first),
            ),
          ),
          const SizedBox(height: 16),
          if (role == 'طاهٍ')
            GridView.count(
              shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisCount: 2, padding: const EdgeInsets.all(12), mainAxisSpacing: 8, crossAxisSpacing: 8, childAspectRatio: .8,
              children: [for (final m in meals) Container(decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(15)), alignment: Alignment.bottomRight, padding: const EdgeInsets.all(8), child: Text('${m.title}\n${m.price} ر.س', style: const TextStyle(fontSize: 12)))],
            )
          else
            Padding(padding: const EdgeInsets.all(24), child: Text(role == 'كابتن' ? 'لا توجد توصيلات الآن' : 'لا توجد طلبات جديدة', textAlign: TextAlign.center, style: const TextStyle(color: C.muted))),
        ]),
      );

  void _settings(BuildContext c) => showModalBottomSheet(
        context: c, backgroundColor: C.card,
        builder: (_) => Column(mainAxisSize: MainAxisSize.min, children: [
          const ListTile(leading: Icon(Icons.notifications_none), title: Text('الإشعارات')),
          const ListTile(leading: Icon(Icons.delete_outline), title: Text('حذف الحساب')),
          ListTile(
            leading: const Icon(Icons.logout), title: const Text('تسجيل الخروج'),
            onTap: () async {
              final p = await SharedPreferences.getInstance();
              await p.setBool('signedIn', false);
              if (c.mounted) Navigator.of(c).popUntil((r) => r.isFirst);
            },
          ),
        ]),
      );
}

class _Stat extends StatelessWidget {
  final String n, l;
  const _Stat(this.n, this.l);
  @override
  Widget build(BuildContext context) => Column(children: [Text(n, style: const TextStyle(fontWeight: FontWeight.w800)), Text(l, style: const TextStyle(fontSize: 11, color: C.line))]);
}
