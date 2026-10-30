import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../model/health_record.dart';
import '../providers/app_providers.dart';
import 'add_record_screen.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;
import 'settings_screen.dart';

/// Documents and photos, filed by person. Amrutham stores them; it doesn't
/// read or interpret them.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final _search = TextEditingController();
  RecordType? _type;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final people = ref.watch(profilesProvider).valueOrNull ?? [];
    final all = ref.watch(recordsProvider).valueOrNull ?? [];
    final q = _search.text.trim().toLowerCase();
    String nameOf(HealthRecord r) =>
        people.where((p) => p.id == r.personId).firstOrNull?.displayName ?? '';
    final shown = [
      for (final r in all)
        if ((_type == null || r.type == _type) &&
            (q.isEmpty ||
                r.title.toLowerCase().contains(q) ||
                (r.source ?? '').toLowerCase().contains(q) ||
                nameOf(r).toLowerCase().contains(q)))
          r,
    ];

    final children = <Widget>[];
    String? group;
    for (final r in shown) {
      final g = '${monthNames[r.recordDate.month - 1]} ${r.recordDate.year}'.toUpperCase();
      if (g != group) {
        group = g;
        children.add(SectionLabel(g));
      }
      children.add(
        Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 44,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F1E8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.description_outlined, color: onboardMuted),
            ),
            title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text(
              '${nameOf(r)} · ${r.type.label} · ${r.recordDate.day} ${monthNames[r.recordDate.month - 1]}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE3ECE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${r.files.length} ${r.files.length == 1 ? 'page' : 'pages'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => RecordDetailScreen(record: r)),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Records',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: 'Settings',
                  ),
                ],
              ),
              const Text('Documents and photos, filed by person.', style: TextStyle(color: onboardMuted)),
              const SizedBox(height: 16),
              TextField(
                controller: _search,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search titles and people',
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text('All · ${all.length}'),
                        selected: _type == null,
                        onSelected: (_) => setState(() => _type = null),
                      ),
                    ),
                    for (final t in RecordType.values)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t.label),
                          selected: _type == t,
                          onSelected: (_) => setState(() => _type = t),
                        ),
                      ),
                  ],
                ),
              ),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Text(
                    'Nothing filed yet. Tap "+ Add" to scan or pick a document.',
                    style: TextStyle(color: onboardMuted),
                  ),
                ),
              ...children,
            ],
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
        heroTag: null,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AddRecordScreen()),
              ),
              backgroundColor: onboardInk,
              foregroundColor: Colors.white,
              label: const Text('+ Add'),
            ),
          ),
        ],
      ),
    );
  }
}

class RecordDetailScreen extends ConsumerStatefulWidget {
  const RecordDetailScreen({super.key, required this.record});

  final HealthRecord record;

  @override
  ConsumerState<RecordDetailScreen> createState() => _RecordDetailState();
}

class _RecordDetailState extends ConsumerState<RecordDetailScreen> {
  int _page = 0;

  static bool _isImage(String path) {
    final e = path.toLowerCase();
    return e.endsWith('.jpg') || e.endsWith('.jpeg') || e.endsWith('.png') || e.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final repository = ref.watch(recordRepositoryProvider).valueOrNull;
    final person = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == r.personId)
        .firstOrNull;
    Widget row(String l, String v) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Expanded(child: Text(l, style: const TextStyle(color: onboardMuted))),
          Text(v, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: const Color(0xFFE3ECE7),
              borderRadius: BorderRadius.circular(28),
            ),
            clipBehavior: Clip.antiAlias,
            child: repository == null || r.files.isEmpty
                ? const SizedBox()
                : PageView.builder(
                    itemCount: r.files.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (_, i) => _isImage(r.files[i])
                        ? InteractiveViewer(
                            child: Image.file(repository.fileFor(r.files[i]), fit: BoxFit.contain),
                          )
                        : Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.description, size: 64, color: onboardMuted),
                                const SizedBox(height: 8),
                                Text(r.files[i].split(Platform.pathSeparator).last),
                              ],
                            ),
                          ),
                  ),
          ),
          if (r.files.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Center(child: Text('${_page + 1} of ${r.files.length}', style: const TextStyle(color: onboardMuted))),
            ),
          const SizedBox(height: 12),
          Text(r.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                row('For', person?.displayName ?? '—'),
                row('Type', r.type.label),
                row('Date', '${r.recordDate.day} ${monthNames[r.recordDate.month - 1]} ${r.recordDate.year}'),
                if (r.source != null) row('From', r.source!),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFE3ECE7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'STORED AS PLAIN FILES',
                  style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w700, color: onboardMuted),
                ),
                for (final f in r.files)
                  Text('vault/$f', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: repository == null
                      ? null
                      : () => SharePlus.instance.share(
                          ShareParams(
                            files: [for (final f in r.files) XFile(repository.fileFor(f).path)],
                            subject: r.title,
                          ),
                        ),
                  child: const Text('Share a copy'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF9B3B2A)),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Delete ${r.title}?'),
                        content: const Text('The files are removed from this phone too.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep')),
                          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (ok != true || repository == null) return;
                    await repository.delete(r.id);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Delete'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Amrutham does not read or interpret this document.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
        ],
      ),
    );
  }
}
