import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme.dart';

/// دخول Google/Apple فقط (قاعدة المالك). الربط الحقيقي مع wardyat-core في المرحلة التالية.
class LoginScreen extends StatelessWidget {
  final VoidCallback onDone;
  const LoginScreen({super.key, required this.onDone});

  Future<void> _enter() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('signedIn', true);
    onDone();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Spacer(),
              Center(
                child: Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: C.orange, border: Border.all(color: Colors.white, width: 3)),
                  child: const Icon(Icons.soup_kitchen_rounded, size: 52, color: Colors.white),
                ),
              ),
              const SizedBox(height: 28),
              const Text('مرحباً بك في مطبخي', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('اكتشف الأكلات المنزلية واطلبها بلمسة', textAlign: TextAlign.center, style: TextStyle(color: C.line)),
              const Spacer(),
              _Btn(icon: Icons.g_mobiledata_rounded, label: 'الدخول بحساب Google', onTap: _enter),
              const SizedBox(height: 12),
              _Btn(icon: Icons.apple, label: 'الدخول بحساب Apple', onTap: _enter),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      );
}

class _Btn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Btn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(
        borderRadius: BorderRadius.circular(15),
        onTap: onTap,
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(15)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 30), const SizedBox(width: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ]),
        ),
      );
}
