import 'package:flutter/material.dart';
import '../data.dart';
import '../theme.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TextField(decoration: InputDecoration(hintText: 'ابحث عن مأكولاتك المفضلة', prefixIcon: const Icon(Icons.search), fillColor: C.field)),
          const SizedBox(height: 16),
          for (final s in sections)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text('#${s.$1}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  Text('${s.$2} فيديو', style: const TextStyle(fontSize: 11, color: C.muted)),
                ]),
                const SizedBox(height: 8),
                Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(19),
                    gradient: LinearGradient(colors: [
                      HSLColor.fromAHSL(1, (s.$2 * 11 % 360).toDouble(), .5, .3).toColor(), C.card,
                    ]),
                  ),
                  child: const Center(child: Icon(Icons.restaurant, size: 40, color: Colors.white54)),
                ),
              ]),
            ),
        ]),
      );
}
