import 'package:flutter/material.dart';

import '../about/legal_text.dart';
import 'app_style.dart';

/// Privacy policy and terms, readable offline.
class LegalScreen extends StatelessWidget {
  const LegalScreen(this.doc, {super.key});

  final LegalDoc doc;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(doc.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(doc.intro, style: const TextStyle(fontSize: 15.5, height: 1.5)),
          const SizedBox(height: 4),
          const Text('Last updated $legalUpdated', style: TextStyle(color: onboardMuted, fontSize: 12.5)),
          for (final s in doc.sections) ...[
            const SizedBox(height: 22),
            Text(s.heading, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            for (final p in s.paragraphs)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(p, style: const TextStyle(height: 1.5)),
              ),
            for (final b in s.bullets)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('•  '),
                    Expanded(child: Text(b, style: const TextStyle(height: 1.5))),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
