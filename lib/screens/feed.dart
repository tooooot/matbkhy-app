import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../api.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

String lastAddress = '';

/// شاشة المنتجات: فيديو وجبة بملء الشاشة وسحب رأسي وزر «اطلب الآن» بالكمية.
class FeedScreen extends StatelessWidget {
  final String? section;
  const FeedScreen({super.key, this.section});
  @override
  Widget build(BuildContext context) => Load<Meal>(
        fetch: () => Api.meals(section: section),
        empty: 'لا توجد وجبات بعد — كن أول من ينشر',
        builder: (_, meals) => PageView.builder(scrollDirection: Axis.vertical, itemCount: meals.length, itemBuilder: (_, i) => MealPage(meals[i])),
      );
}

class MealPage extends StatefulWidget {
  final Meal m;
  const MealPage(this.m, {super.key});
  @override
  State<MealPage> createState() => _MealPageState();
}

class _MealPageState extends State<MealPage> {
  int qty = 1, likes = 0;
  bool liked = false, busy = false;
  VideoPlayerController? vc;

  @override
  void initState() {
    super.initState();
    likes = widget.m.likes;
    final v = widget.m.video;
    if (v != null) {
      vc = VideoPlayerController.networkUrl(Uri.parse(v))
        ..setLooping(true)
        ..initialize().then((_) {
          if (mounted) {
            setState(() {});
            vc!.play();
          }
        }).catchError((_) {});
    }
  }

  @override
  void dispose() {
    vc?.dispose();
    super.dispose();
  }

  Future<void> _like() async {
    try {
      final r = await Api.like(widget.m.id);
      setState(() {
        liked = r['liked'];
        likes = r['likes'];
      });
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  Future<void> _order() async {
    final ctl = TextEditingController(text: lastAddress);
    final addr = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: C.card,
        title: const Text('عنوان التوصيل'),
        content: TextField(controller: ctl, decoration: const InputDecoration(hintText: 'المدينة، الحي، الشارع')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('إلغاء')),
          TextButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: const Text('تأكيد الطلب', style: TextStyle(color: C.orange))),
        ],
      ),
    );
    if (addr == null || addr.isEmpty) return;
    setState(() => busy = true);
    try {
      lastAddress = addr;
      await Api.placeOrder([(widget.m.id, qty)], addr);
      if (mounted) toast(context, 'وصل طلبك للطاهي');
    } catch (e) {
      if (mounted) toast(context, '$e');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.m;
    final ready = vc != null && vc!.value.isInitialized;
    return Stack(fit: StackFit.expand, children: [
      if (ready)
        FittedBox(fit: BoxFit.cover, child: SizedBox(width: vc!.value.size.width, height: vc!.value.size.height, child: VideoPlayer(vc!)))
      else
        Image.asset(m.img, fit: BoxFit.cover),
      const DecoratedBox(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.center, end: Alignment.bottomCenter, colors: [Colors.transparent, Color(0xDD000000)])),
      ),
      if (m.video != null && !ready) const Center(child: CircularProgressIndicator(color: C.orange)),
      Positioned(
        right: 12, bottom: 160,
        child: Column(children: [
          GestureDetector(onTap: _like, child: _Act(Icons.favorite, '$likes', on: liked)),
          const _Act(Icons.share, ''), _Act(Icons.chat_bubble, '${m.comments}'),
        ]),
      ),
      Positioned(
        left: 16, right: 70, bottom: 84,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(m.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('${m.chef} · ${m.area}', style: const TextStyle(fontSize: 12, color: C.line)),
          Text('#${m.section}', style: const TextStyle(fontWeight: FontWeight.w700)),
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
                IconButton(onPressed: () => setState(() => qty = qty < m.qty ? qty + 1 : qty), icon: const Icon(Icons.add_circle)),
              ]),
            ),
            Expanded(
              child: InkWell(
                onTap: busy || m.qty < 1 ? null : _order,
                child: Center(child: Text(m.qty < 1 ? 'نفدت الكمية' : 'اطلب الآن ( ${m.price * qty} ريال )', style: const TextStyle(fontWeight: FontWeight.w800))),
              ),
            ),
          ]),
        ),
      ),
    ]);
  }
}

class _Act extends StatelessWidget {
  final IconData i;
  final String t;
  final bool on;
  const _Act(this.i, this.t, {this.on = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(children: [Icon(i, size: 30, color: on ? C.orange : Colors.white), Text(t, style: const TextStyle(fontSize: 11))]),
      );
}
