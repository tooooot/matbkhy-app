import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'api.dart';
import 'screens/login.dart';
import 'screens/shell.dart';
import 'theme.dart';

void main() => runApp(const MatbkhyApp());

class MatbkhyApp extends StatelessWidget {
  const MatbkhyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'مطبخي',
        debugShowCheckedModeBanner: false,
        theme: matbkhyTheme(),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Boot(),
      );
}

/// يقرأ الجلسة المحفوظة ثم يفتح التطبيق أو شاشة الدخول.
class Boot extends StatefulWidget {
  const Boot({super.key});
  @override
  State<Boot> createState() => _BootState();
}

class _BootState extends State<Boot> {
  bool loaded = false;
  @override
  void initState() {
    super.initState();
    Api.load().whenComplete(() {
      if (mounted) setState(() => loaded = true);
    });
  }

  void refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    if (!loaded) return const Scaffold(body: Center(child: CircularProgressIndicator(color: C.orange)));
    return Api.signedIn ? Shell(onSignedOut: refresh) : LoginScreen(onDone: refresh);
  }
}
