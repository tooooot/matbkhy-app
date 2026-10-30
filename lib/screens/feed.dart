import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

/// شاشة المنتجات: فيديو وجبة بملء الشاشة وسحب رأسي وزر «اطلب الآن» بالكمية.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});
  @override
  Widget build(BuildContext context) => PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: meals.length,
        itemBuilder: (_, i) => _MealPage(meals[i]),
      );
}

class _MealPage extends StatefulWidget {
  final Meal m;
  const _MealPage(this.m);
  @override
  State<_MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<_MealPage> {
  int qty = 1;
  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    return Stack(fit: StackFit.expand, children: [
      Image.asset(m.img, fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD000000)]),
        ),
      ),
      const Center(child: Icon(Icons.play_circle_fill_rounded, size: 84, color: C.orange)),
      Positioned(
        right: 12, bottom: 160,
        child: Column(children: [
          _Act(Icons.favorite, '${m.likes}'), _Act(Icons.share, '214'), _Act(Icons.bookmark, '17'), _Act(Icons.chat_bubble, '${m.comments}'),
        ]),
      ),
      Positioned(
        left: 16, right: 70, bottom: 84,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(m.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text('${m.chef} · ${m.area}', style: const TextStyle(fontSize: 12, color: C.line)),
          Text('#${m.tag}', style: const TextStyle(fontWeight: FontWeight.w700)),
          Text(m.desc, style: const TextStyle(fontSize: 12, color: C.line)),
        ]),
      ),
      Positioned(
        left: 12, right: 12, bottom: 16,
        child: Container(
          height: 50,
          decoration: BoxDecoration(color: C.orange, borderRadius: BorderRadius.circular(15)),
          child: Row(children: [
            Directionality(
              textDirection: TextDirection.ltr,
              child: Row(children: [
                IconButton(onPressed: () => setState(() => qty = qty > 1 ? qty - 1 : 1), icon: const Icon(Icons.remove_circle)),
                Text('$qty', style: const TextStyle(fontWeight: FontWeight.w700)),
                IconButton(onPressed: () => setState(() => qty++), icon: const Icon(Icons.add_circle)),
              ]),
            ),
            const Spacer(),
            Text('اطلب الآن ( ${m.price * qty} ريال )', style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(width: 16),
          ]),
        ),
      ),
    ]);
  }
}

class _Act extends StatelessWidget {
  final IconData i; final String t;
  const _Act(this.i, this.t);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(children: [Icon(i, size: 30), Text(t, style: const TextStyle(fontSize: 11))]),
      );
}
