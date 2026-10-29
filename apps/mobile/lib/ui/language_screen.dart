import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';
import 'app_style.dart';
import 'strings.dart';

/// Choose the app language. Set on this phone only.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);
    Widget row((String, String, String) l) {
      final (code, native, english) = l;
      final ready = available.contains(code);
      return ListTile(
        enabled: ready,
        title: Text(native, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        subtitle: Text(english),
        trailing: code == current
            ? const Icon(Icons.check, color: onboardInk)
            : Text(
                ready ? 'App only' : 'Not yet',
                style: const TextStyle(color: onboardMuted, fontSize: 12),
              ),
        onTap: ready ? () => ref.read(languageProvider.notifier).choose(code) : null,
      );
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            tr(context, 'Language'),
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set on this phone only. Nothing about your language is sent anywhere.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
          const SectionLabel('India'),
          Card(child: Column(children: [for (final l in languages.take(6)) row(l)])),
          const SectionLabel('World'),
          Card(child: Column(children: [for (final l in languages.skip(6)) row(l)])),
          const SectionLabel('What "App only" means'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tabs and a few main buttons are translated. Health guides appear '
                'in English: they are never machine-translated, because a wrong '
                'word in a medical guide can cause harm. Medicine names stay as '
                'printed on the label.',
                style: TextStyle(height: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
