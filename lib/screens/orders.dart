import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('طلباتي'),
            bottom: const TabBar(indicatorColor: C.orange, labelColor: C.orange, unselectedLabelColor: Colors.white, tabs: [
              Tab(text: 'قيد الانتظار'), Tab(text: 'منتهية'),
            ]),
          ),
          body: TabBarView(children: [
            ListView(padding: const EdgeInsets.all(12), children: [for (final m in meals.take(2)) _Row(m, pending: true)]),
            ListView(padding: const EdgeInsets.all(12), children: [for (final m in meals.skip(2)) _Row(m, pending: false)]),
          ]),
        ),
      );
}

class _Row extends StatelessWidget {
  final Meal m; final bool pending;
  const _Row(this.m, {required this.pending});
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: C.card, borderRadius: BorderRadius.circular(15)),
        child: Row(children: [
          Container(width: 64, height: 64, decoration: BoxDecoration(color: C.field, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.fastfood, color: C.orange)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(m.chef, style: const TextStyle(color: C.orange, fontSize: 12)),
          ])),
          Text('${m.price} ر.س', style: const TextStyle(fontWeight: FontWeight.w800)),
          if (pending) ...[const SizedBox(width: 8), const Icon(Icons.delete_outline, color: C.orange)],
        ]),
      );
}
