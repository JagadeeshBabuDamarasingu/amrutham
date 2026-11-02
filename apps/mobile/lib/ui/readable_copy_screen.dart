import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../backup/readable_copy.dart';
import '../model/ids.dart';
import '../providers/app_providers.dart';
import 'app_style.dart';

/// Last resort: plain files with no code, shared through the phone's own
/// share sheet. The person chooses where they go and accepts the risk.
class ReadableCopyScreen extends ConsumerStatefulWidget {
  const ReadableCopyScreen({super.key});

  @override
  ConsumerState<ReadableCopyScreen> createState() => _ReadableCopyScreenState();
}

class _ReadableCopyScreenState extends ConsumerState<ReadableCopyScreen> {
  final _off = <PersonId>{};
  var _agreed = false;
  var _busy = false;

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final people = (ref.read(profilesProvider).valueOrNull ?? []).where((p) => !_off.contains(p.id)).toList();
      final data = <PersonData>[
        for (final p in people)
          PersonData(
            p,
            allergies: await ref.read(allergiesProvider(p.id).future),
            medicines: await ref.read(medicationCoursesProvider(p.id).future),
            history: await ref.read(historyEventsProvider(p.id).future),
            measurements: await ref.read(measurementsProvider(p.id).future),
          ),
      ];
      final files = readableCopy(
        data,
        ref.read(expensesProvider).valueOrNull ?? [],
        ref.read(profilesProvider).valueOrNull ?? [],
      );
      final dir = await getTemporaryDirectory();
      final shared = <XFile>[];
      for (final e in files.entries) {
        final f = File('${dir.path}/${e.key}');
        await f.writeAsString(e.value);
        shared.add(XFile(f.path, mimeType: e.key.endsWith('.csv') ? 'text/csv' : 'text/plain'));
      }
      await SharePlus.instance.share(ShareParams(files: shared, subject: 'Amrutham readable copy'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    final chosen = people.where((p) => !_off.contains(p.id)).length;
    return Scaffold(
      backgroundColor: onboardBg,
      appBar: AppBar(backgroundColor: onboardBg, title: const Text('Save a readable copy')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'A plain copy of your records that opens on any phone or computer, with no code and no app. Use it if a normal backup is not possible.',
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFF7DDDA), borderRadius: BorderRadius.circular(18)),
            child: const Text(
              'This copy is not protected. Anyone who finds this file can read everything in it. Once it leaves Amrutham we cannot protect it, track it or delete it. You choose where it goes, and keeping it safe is up to you.',
              style: TextStyle(color: Color(0xFF5A1D17)),
            ),
          ),
          const SectionLabel('Whose records'),
          Card(
            child: Column(
              children: [
                for (final p in people)
                  CheckboxListTile(
                    title: Text(p.displayName),
                    value: !_off.contains(p.id),
                    onChanged: (v) => setState(() => v! ? _off.remove(p.id) : _off.add(p.id)),
                  ),
              ],
            ),
          ),
          const SectionLabel('What goes in'),
          const Card(
            child: ListTile(
              title: Text('A summary and a table for each person'),
              subtitle: Text('Text: medicines, allergies, history, contacts. CSV: measurements and expenses. Saved documents are not included; copy the Amrutham folder for those.'),
            ),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _agreed,
            onChanged: (v) => setState(() => _agreed = v ?? false),
            title: const Text('I understand this copy is not protected, and I am responsible for where it is saved and who can see it.'),
          ),
          const SizedBox(height: 8),
          OnboardButton(
            label: _busy ? 'Preparing…' : 'Choose where to save it',
            onPressed: _agreed && chosen > 0 && !_busy ? _save : null,
          ),
          const SizedBox(height: 12),
          const Text(
            "Your phone's share sheet opens next: Files, Drive, email or a USB drive. Delete the copy when you no longer need it.",
            textAlign: TextAlign.center,
            style: TextStyle(color: onboardMuted, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
