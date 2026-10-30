import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../api.dart';
import '../theme.dart';
import '../widgets.dart';

/// دخول Google/Apple فقط؛ التحقق من الرمز يتم في wardyat-core.
class LoginScreen extends StatefulWidget {
  final VoidCallback onDone;
  const LoginScreen({super.key, required this.onDone});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool busy = false;
  Map<String, dynamic> cfg = {};

  @override
  void initState() {
    super.initState();
    Api.publicConfig().then((c) {
      if (mounted) setState(() => cfg = c);
    }).catchError((_) {});
  }

  Future<void> _run(Future<String?> Function() getToken, String provider) async {
    setState(() => busy = true);
    try {
      final t = await getToken();
      if (t == null) return;
      await Api.socialLogin(provider, t);
      widget.onDone();
    } catch (e) {
      if (mounted) toast(context, 'تعذّر تسجيل الدخول: $e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<String?> _google() async {
    final id = '${cfg['googleClientId'] ?? ''}';
    if (id.isEmpty) throw 'الدخول بـ Google غير مفعّل بعد';
    await GoogleSignIn.instance.initialize(serverClientId: id);
    return (await GoogleSignIn.instance.authenticate()).authentication.idToken;
  }

  Future<String?> _apple() async =>
      (await SignInWithApple.getAppleIDCredential(scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName])).identityToken;

  @override
  Widget build(BuildContext context) {
    final showApple = kIsWeb || defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
    return Scaffold(
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
            if (busy) const Center(child: CircularProgressIndicator(color: C.orange)) else ...[
              _Btn(icon: Icons.g_mobiledata_rounded, label: 'الدخول بحساب Google', onTap: () => _run(_google, 'google')),
              if (showApple) ...[const SizedBox(height: 12), _Btn(icon: Icons.apple, label: 'الدخول بحساب Apple', onTap: () => _run(_apple, 'apple'))],
            ],
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
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
