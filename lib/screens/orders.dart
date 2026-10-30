import 'package:flutter/material.dart';
import '../api.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => FutureBuilder<List<Order>>(
        future: Api.myOrders(),
        builder: (c, s) {
          final all = s.data ?? const <Order>[];
          return DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                title: const Text('طلباتي'),
                bottom: const TabBar(indicatorColor: C.orange, labelColor: C.orange, unselectedLabelColor: Colors.white, tabs: [Tab(text: 'قيد الانتظار'), Tab(text: 'منتهية')]),
              ),
              body: s.connectionState != ConnectionState.done
                  ? const Center(child: CircularProgressIndicator(color: C.orange))
                  : s.hasError
                      ? Center(child: Text('${s.error}', style: const TextStyle(color: C.line)))
                      : TabBarView(children: [
                          OrderList([for (final o in all) if (o.open) o], cancellable: true),
                          OrderList([for (final o in all) if (!o.open) o]),
                        ]),
            ),
          );
        },
      );
}

class OrderList extends StatelessWidget {
  final List<Order> orders;
  final bool cancellable;
  final List<(String, String)> Function(Order)? actions;
  const OrderList(this.orders, {super.key, this.cancellable = false, this.actions});
  @override
  Widget build(BuildContext context) => orders.isEmpty
      ? const Center(child: Text('لا توجد طلبات', style: TextStyle(color: C.muted)))
      : ListView(padding: const EdgeInsets.all(12), children: [for (final o in orders) OrderCard(o, cancellable: cancellable, actions: actions?.call(o) ?? const [])]);
}

class OrderCard extends StatefulWidget {
  final Order o;
  final bool cancellable;
  final List<(String, String)> actions;
  const OrderCard(this.o, {super.key, this.cancellable = false, this.actions = const []});
  @override
  State<OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<OrderCard> {
  Future<void> _set(String st) async {
    try {
      await Api.setStatus(widget.o.id, st);
      if (mounted) toast(context, 'تم التحديث — اسحب للتحديث');
    } catch (e) {
      if (mounted) toast(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    return Container(
      margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(15)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(o.items.map((i) => '${i.title} × ${i.qty}').join('، '), style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('${o.total} ر.س', style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        Text(o.statusAr, style: const TextStyle(color: C.orange, fontSize: 12)),
        Text(o.address, style: const TextStyle(color: C.muted, fontSize: 11)),
        if (widget.cancellable && o.status == 'pending') TextButton(onPressed: () => _set('cancelled'), child: const Text('إلغاء الطلب', style: TextStyle(color: C.orange))),
        if (widget.actions.isNotEmpty) Row(children: [for (final a in widget.actions) Padding(padding: const EdgeInsetsDirectional.only(end: 8), child: FilledButton(style: FilledButton.styleFrom(minimumSize: const Size(90, 38)), onPressed: () => _set(a.$1), child: Text(a.$2)))]),
      ]),
    );
  }
}
