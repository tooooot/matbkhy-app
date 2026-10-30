import 'package:flutter/material.dart';
import '../theme.dart';
import 'feed.dart';
import 'sections.dart';
import 'orders.dart';
import 'account.dart';

/// الشريط السفلي الثابت: المنتجات، الأقسام، (+ نشر)، طلباتي، حسابي.
class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int i = 0;
  @override
  Widget build(BuildContext context) {
    const pages = [FeedScreen(), SectionsScreen(), OrdersScreen(), AccountScreen()];
    return Scaffold(
      body: pages[i],
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: FloatingActionButton(
        backgroundColor: C.orange, foregroundColor: Colors.white, shape: const CircleBorder(),
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('نشر وجبة بفيديو — قريباً'))),
        child: const Icon(Icons.add, size: 32),
      ),
      bottomNavigationBar: BottomAppBar(
        color: C.bg, shape: const CircularNotchedRectangle(), notchMargin: 6,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _Tab(Icons.play_arrow_rounded, 'المنتجات', i == 0, () => setState(() => i = 0)),
          _Tab(Icons.grid_view_rounded, 'الأقسام', i == 1, () => setState(() => i = 1)),
          const SizedBox(width: 48),
          _Tab(Icons.shopping_bag_outlined, 'طلباتي', i == 2, () => setState(() => i = 2)),
          _Tab(Icons.person_outline, 'حسابي', i == 3, () => setState(() => i = 3)),
        ]),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final IconData icon; final String label; final bool on; final VoidCallback tap;
  const _Tab(this.icon, this.label, this.on, this.tap);
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: tap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: on ? C.orange : C.muted),
            Text(label, style: TextStyle(fontSize: 11, color: on ? C.orange : C.muted)),
          ]),
        ),
      );
}
