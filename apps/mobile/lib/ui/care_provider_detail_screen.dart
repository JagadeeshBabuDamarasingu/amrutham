import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/care_provider.dart';
import '../model/expense.dart';
import '../model/history_event.dart';
import '../model/ids.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import 'add_care_provider_screen.dart';
import 'app_style.dart';
import 'log_measurement_screen.dart' show monthNames;

/// One doctor or place (frames 5b and 5d): who they are, how to reach them, and
/// what the app already knows about visits and spending. Read live, so an edit
/// shows straight away.
class CareProviderDetailScreen extends ConsumerWidget {
  const CareProviderDetailScreen({super.key, required this.providerId, required this.personId});

  final CareProviderId providerId;

  /// The person whose care team it was opened from; "Edit" starts from them.
  final PersonId personId;

  Future<void> _open(BuildContext context, Uri uri, String failed) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failed)));
    }
  }

  static String _day(DateTime d) => '${d.day} ${monthNames[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final all = ref.watch(careProvidersAllProvider).valueOrNull ?? const <CareProvider>[];
    final p = all.where((x) => x.id == providerId).firstOrNull;
    if (p == null) return Scaffold(appBar: AppBar(), body: const SizedBox());
    final people = ref.watch(profilesProvider).valueOrNull ?? const [];
    final names = [for (final x in people) if (p.personIds.contains(x.id)) x.firstName];
    final events = <HistoryEvent>[
      for (final id in p.personIds) ...?ref.watch(historyEventsProvider(id)).valueOrNull,
    ];
    final expenses = ref.watch(expensesProvider).valueOrNull ?? const <Expense>[];
    final now = DateTime.now();
    final summary = summarizeCare(p, events, expenses, now);

    final isDoctor = p.kind == CareKind.doctor;
    final workplace = p.worksAt == null
        ? null
        : all.where((x) => x.kind == CareKind.facility && careNameKey(x.name) == careNameKey(p.worksAt!)).firstOrNull;
    final doctorsHere = isDoctor
        ? const <CareProvider>[]
        : all
              .where((x) => x.kind == CareKind.doctor && x.worksAt != null && careNameKey(x.worksAt!) == careNameKey(p.name))
              .toList();

    Widget line(String label, String value, {VoidCallback? onTap}) => InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: onboardMuted)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                onTap == null ? value : '$value ›',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: onTap == null ? FontWeight.w500 : FontWeight.w700, color: onTap == null ? null : onboardInk),
              ),
            ),
          ],
        ),
      ),
    );

    Widget action(IconData icon, String label, VoidCallback? onTap) => Expanded(
      child: Opacity(
        opacity: onTap == null ? 0.4 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                Icon(icon, size: 20, color: onboardInk),
                const SizedBox(height: 5),
                Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );

    final location = p.location;
    final visitCount = summary.visits;
    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => AddCareProviderScreen(personId: personId, editing: p)),
            ),
            child: const Text('Edit'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Row(
              children: [
                Container(
                  width: 62,
                  height: 62,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: const Color(0xFF2D5246), borderRadius: BorderRadius.circular(22)),
                  child: isDoctor
                      ? Text(
                          careInitials(p.name),
                          style: const TextStyle(fontFamily: headingFont, fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFFD6E6DE)),
                        )
                      : const Icon(Icons.local_hospital_outlined, color: Color(0xFFD6E6DE), size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(fontFamily: headingFont, color: Colors.white, fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        [
                          if (isDoctor) ?p.specialty else 'Hospital or clinic',
                          if (names.isNotEmpty) 'for ${names.join(', ')}',
                        ].join(' · '),
                        style: const TextStyle(color: Color(0xFFB8D0C5)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              action(
                Icons.call_outlined,
                'Call',
                p.phone == null ? null : () => _open(context, Uri(scheme: 'tel', path: p.phone), "Couldn't open the dialer"),
              ),
              const SizedBox(width: 10),
              action(
                Icons.chat_bubble_outline,
                'Message',
                p.phone == null ? null : () => _open(context, Uri(scheme: 'sms', path: p.phone), "Couldn't open messages"),
              ),
              const SizedBox(width: 10),
              action(
                Icons.place_outlined,
                'Directions',
                location == null
                    ? null
                    : () => _open(
                        context,
                        Uri.parse('geo:0,0?q=${Uri.encodeComponent(location)}'),
                        "Couldn't open a maps app",
                      ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  if (p.phone != null) line('Phone', p.phone!),
                  if (isDoctor && p.worksAt != null)
                    line(
                      'Works at',
                      p.worksAt!,
                      onTap: workplace == null
                          ? null
                          : () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CareProviderDetailScreen(providerId: workplace.id, personId: personId),
                              ),
                            ),
                    ),
                  if (location != null) line('Location', location),
                  if (p.phone == null && location == null && (!isDoctor || p.worksAt == null))
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('No details added yet. Tap Edit to add a phone number or address.', style: TextStyle(color: onboardMuted)),
                    ),
                ],
              ),
            ),
          ),
          if (doctorsHere.isNotEmpty) ...[
            const SectionLabel('Doctors here'),
            Card(
              child: Column(
                children: [
                  for (final d in doctorsHere)
                    ListTile(
                      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: d.specialty == null ? null : Text(d.specialty!),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CareProviderDetailScreen(providerId: d.id, personId: personId),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SectionLabel('Visits'),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              child: Column(
                children: [
                  line('Last visit', summary.lastVisit == null ? 'None recorded' : _day(summary.lastVisit!.eventDate)),
                  line('Next visit', summary.nextVisit == null ? 'None planned' : '${_day(summary.nextVisit!.eventDate)}, ${summary.nextVisit!.title}'),
                  line('Recorded visits', '$visitCount'),
                  line('Spent here, ${now.year}', formatRupees(summary.spentThisYear)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Visits and spending are matched by name from your history and expenses. '
            'Add this name as the doctor or hospital on an entry, and it shows up here.',
            style: TextStyle(color: onboardMuted, height: 1.4, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
