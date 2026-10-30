import 'package:flutter/material.dart';
import 'theme.dart';

/// يعرض حالات التحميل والخطأ والفراغ لأي طلب، مع سحب للتحديث.
class Load<T> extends StatefulWidget {
  final Future<List<T>> Function() fetch;
  final Widget Function(BuildContext, List<T>) builder;
  final String empty;
  const Load({super.key, required this.fetch, required this.builder, this.empty = 'لا يوجد شيء هنا بعد'});
  @override
  State<Load<T>> createState() => LoadState<T>();
}

class LoadState<T> extends State<Load<T>> {
  late Future<List<T>> f = widget.fetch();
  void reload() => setState(() => f = widget.fetch());
  @override
  Widget build(BuildContext context) => FutureBuilder<List<T>>(
        future: f,
        builder: (c, s) {
          if (s.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator(color: C.orange));
          if (s.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.wifi_off, size: 40, color: C.muted),
                const SizedBox(height: 8),
                Text('${s.error}', textAlign: TextAlign.center, style: const TextStyle(color: C.line)),
                TextButton(onPressed: reload, child: const Text('إعادة المحاولة', style: TextStyle(color: C.orange))),
              ]),
            );
          }
          final d = s.data!;
          if (d.isEmpty) return Center(child: Text(widget.empty, style: const TextStyle(color: C.muted)));
          return RefreshIndicator(color: C.orange, onRefresh: () async => reload(), child: widget.builder(c, d));
        },
      );
}

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
