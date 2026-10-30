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
                ClipRRect(
                  borderRadius: BorderRadius.circular(19),
                  child: Image.asset('assets/img/${s.$3}.jpg', height: 150, width: double.infinity, fit: BoxFit.cover),
                ),
              ]),
            ),
        ]),
      );
}
