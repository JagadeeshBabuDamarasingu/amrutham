import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../model/allergy.dart';
import '../model/certainty.dart';
import '../model/ids.dart';
import '../model/medication.dart';
import '../model/person.dart';
import '../providers/app_providers.dart';
import '../quick_access/emergency_snapshot.dart' show shortBlood;
import 'app_style.dart';

/// One page a stranger can read: blood group, allergies, what the person is
/// taking, who to call. Built from what's already recorded; entries that
/// aren't confirmed say so ("as reported") rather than looking verified.
class EmergencyCardScreen extends ConsumerWidget {
  const EmergencyCardScreen({super.key, required this.personId});

  final PersonId personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final person = ref
        .watch(profilesProvider)
        .valueOrNull
        ?.where((p) => p.id == personId)
        .firstOrNull;
    final allergies = ref.watch(allergiesProvider(personId)).valueOrNull ?? [];
    final courses =
        ref.watch(activeCoursesProvider(personId)).valueOrNull ?? [];

    if (person == null) return const Scaffold(body: SizedBox());

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    color: onboardInk,
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EMERGENCY CARD',
                                style: TextStyle(
                                  color: Color(0xFFB8D0C5),
                                  fontSize: 12,
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                person.displayName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: onboardAmber,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'BLOOD',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                _shortBlood(person.bloodGroup),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Block(
                    'Allergies',
                    allergies.isEmpty
                        ? [const Text('None recorded')]
                        : [for (final a in allergies) Text(_allergyLine(a))],
                  ),
                  _Block(
                    'Taking now',
                    courses.isEmpty
                        ? [const Text('No active medicines')]
                        : [for (final c in courses) _MedLine(course: c)],
                  ),
                  _Block('Call', [
                    if (person.emergencyContacts.isEmpty)
                      const Text('No contacts added'),
                    for (final c in person.emergencyContacts)
                      Text(
                        '${c.name}'
                        '${c.relationship == null ? '' : ' (${c.relationship})'}'
                        ' ${c.phone}',
                      ),
                    TextButton(
                      onPressed: () => _addContact(context, ref),
                      child: const Text('+ Add contact'),
                    ),
                  ]),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          OnboardButton(
            label: 'Share copy',
            onPressed: () => SharePlus.instance.share(
              ShareParams(
                subject: 'Emergency card: ${person.displayName}',
                text: _plainText(person, allergies, courses),
              ),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            onPressed: () => Printing.layoutPdf(
              name: 'Emergency card ${person.displayName}',
              // HTML, not drawn PDF text: the phone's own renderer has the
              // fonts for Telugu, Hindi and Urdu names.
              onLayout: (format) => Printing.convertHtml(
                format: format,
                html: cardHtml(person, allergies, courses),
              ),
            ),
            child: const Text('Print or save as PDF'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Printed or shared, it works even if this phone is lost, locked '
            'or dead. Entries marked "as reported" are not verified.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
        ],
      ),
    );
  }

  static String _shortBlood(String? group) => shortBlood(group);

  static String _allergyLine(AllergyRecord a) =>
      '${a.substance} · ${a.reaction}'
      '${a.certainty == Certainty.confirmed ? '' : ' · as ${a.certainty.name}'}';

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  /// The printable page: the same facts as the plain text, large and plain.
  @visibleForTesting
  static String cardHtml(
    PersonProfile p,
    List<AllergyRecord> allergies,
    List<MedicationCourse> courses,
  ) {
    String row(String label, String value) =>
        '<p><b>${_esc(label)}</b><br>${_esc(value)}</p>';
    return '<html><body style="font-family:sans-serif;font-size:20px">'
        '<h1>Emergency card: ${_esc(p.displayName)}</h1>'
        '${row('Blood group', p.bloodGroup ?? 'not recorded')}'
        '${row('Allergies', allergies.isEmpty ? 'none recorded' : allergies.map(_allergyLine).join('; '))}'
        '${row('Taking now', courses.isEmpty ? 'none' : courses.map((c) => c.medicationName).join(', '))}'
        '${row('Call', p.emergencyContacts.isEmpty ? 'no contacts added' : p.emergencyContacts.map((c) => '${c.name} ${c.phone}').join('; '))}'
        '<p style="font-size:14px">Entries marked "as reported" are not verified.</p>'
        '</body></html>';
  }

  static String _plainText(
    PersonProfile p,
    List<AllergyRecord> allergies,
    List<MedicationCourse> courses,
  ) {
    final b = StringBuffer('EMERGENCY CARD: ${p.displayName}\n');
    b.writeln('Blood group: ${p.bloodGroup ?? 'not recorded'}');
    b.writeln(
      'Allergies: ${allergies.isEmpty ? 'none recorded' : allergies.map(_allergyLine).join('; ')}',
    );
    b.writeln(
      'Taking now: ${courses.isEmpty ? 'none' : courses.map((c) => c.medicationName).join(', ')}',
    );
    b.writeln(
      'Call: ${p.emergencyContacts.isEmpty ? 'no contacts added' : p.emergencyContacts.map((c) => '${c.name} ${c.phone}').join('; ')}',
    );
    return b.toString();
  }

  Future<void> _addContact(BuildContext context, WidgetRef ref) async {
    final contact = await showDialog<EmergencyContact>(
      context: context,
      builder: (_) => const _ContactDialog(),
    );
    if (contact == null) return;
    final repository = await ref.read(profileRepositoryProvider.future);
    await repository.addEmergencyContact(personId, contact);
  }
}

/// Owns its text controllers, so they are disposed with the dialog and never
/// while it is still animating closed.
class _ContactDialog extends StatefulWidget {
  const _ContactDialog();

  @override
  State<_ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<_ContactDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _relation = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _relation.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      EmergencyContact(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        relationship: _relation.text.trim().isEmpty ? null : _relation.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Emergency contact'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _relation,
              decoration: const InputDecoration(labelText: 'Relationship (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block(this.label, this.children);

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE3ECE7))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              letterSpacing: 1,
              fontWeight: FontWeight.w700,
              color: onboardMuted,
            ),
          ),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}

class _MedLine extends ConsumerWidget {
  const _MedLine({required this.course});

  final MedicationCourse course;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final phase = ref
        .watch(schedulePhasesProvider(course.id))
        .valueOrNull
        ?.firstOrNull;
    final dose = phase == null ? '' : ', ${phase.doseAmount}';
    return Text('${course.medicationName}$dose');
  }
}
