import 'package:flutter/material.dart';
import '../api.dart';
import '../data.dart';
import '../theme.dart';
import '../widgets.dart';
import 'feed.dart';

class SectionsScreen extends StatelessWidget {
  const SectionsScreen({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
        child: Load<SectionInfo>(
          fetch: Api.sections,
          builder: (_, secs) => ListView(padding: const EdgeInsets.all(16), children: [
            for (final s in secs)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => Scaffold(appBar: AppBar(title: Text(s.name)), body: FeedScreen(section: s.name)))),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Text('#${s.name}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      Text('${s.count} وجبة', style: const TextStyle(fontSize: 11, color: C.muted)),
                    ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Image.asset('assets/img/${sectionImages[s.name] ?? 'brunch'}.jpg', height: 150, width: double.infinity, fit: BoxFit.cover),
                    ),
                  ]),
                ),
              ),
          ]),
        ),
      );
}
