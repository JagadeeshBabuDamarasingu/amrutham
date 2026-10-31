import 'package:amrutham_widgets/amrutham_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/person.dart';
import '../providers/app_providers.dart';
import '../quick_access/widget_settings.dart';
import 'app_style.dart';

/// How many cards each person has on the home screen. Read when the screen
/// opens; the phone, not the app, owns the widgets.
final cardCountsProvider = FutureProvider.autoDispose<Map<String, int>>(
  (ref) => AmruthamWidgets.cardCounts(),
);

Future<void> _save(WidgetRef ref, WidgetSettings settings) async {
  await ref.read(onboardingStoreProvider).putSetting(WidgetSettings.storeKey, settings.encode());
  ref.invalidate(widgetSettingsProvider);
}

/// Settings > Home screen widgets: a master switch, then one row per person.
class WidgetsSettingsScreen extends ConsumerWidget {
  const WidgetsSettingsScreen({super.key});

  Future<void> _toggle(BuildContext context, WidgetRef ref, WidgetSettings s, bool on) async {
    if (on) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Turn on home screen cards?'),
          content: const Text(
            'Amrutham keeps a small copy of what you choose to show, in a file '
            'on this phone, so the home screen can display it. Anyone who sees '
            'your home screen can read it. The copy is not part of your '
            'backups, and it is deleted when you turn this off.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialog, false), child: const Text('Not now')),
            TextButton(onPressed: () => Navigator.pop(dialog, true), child: const Text('Turn on')),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _save(ref, s.withEnabled(on));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(widgetSettingsProvider).valueOrNull ?? const WidgetSettings();
    final people = [
      for (final p in ref.watch(profilesProvider).valueOrNull ?? const <PersonProfile>[])
        if (!p.isDeceased) p,
    ];
    final counts = ref.watch(cardCountsProvider).valueOrNull ?? const {};
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            'Home screen widgets',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 8),
          const Text(
            'Anything you show is visible to anyone who sees your home screen. '
            'Nothing is shown until you add it.',
            style: TextStyle(color: onboardMuted, height: 1.4),
          ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              title: const Text('Emergency cards', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Put a card on your home screen with name, blood group, allergies and a button to dial a contact.'),
              value: settings.enabled,
              onChanged: (on) => _toggle(context, ref, settings, on),
            ),
          ),
          if (settings.enabled) ...[
            const SectionLabel('Cards'),
            if (people.isEmpty) const Text('Add a family member first.'),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < people.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                      leading: PersonAvatar(name: people[i].displayName, size: 40),
                      title: Text(people[i].displayName, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text(_cardCount(counts[people[i].id.value] ?? 0)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CardOptionsScreen(person: people[i])),
                        );
                        ref.invalidate(cardCountsProvider);
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Add as many cards as you like, for different people or the same '
              'person in more than one place. Tap a person to choose what their '
              'cards show. To remove a card, touch and hold it on your home screen.',
              style: TextStyle(color: onboardMuted, height: 1.4, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  static String _cardCount(int n) => switch (n) {
    0 => 'Not on your home screen',
    1 => '1 card on your home screen',
    _ => '$n cards on your home screen',
  };
}

/// What one person's cards show, and the button that adds one.
class CardOptionsScreen extends ConsumerWidget {
  const CardOptionsScreen({super.key, required this.person});

  final PersonProfile person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(widgetSettingsProvider).valueOrNull ?? const WidgetSettings();
    final o = settings.optionsFor(person.id.value);
    void change(CardOptions next) => _save(ref, settings.withOptions(person.id.value, next));
    final contacts = person.emergencyContacts;

    Widget toggle(String title, String sub, bool value, ValueChanged<bool> on) => SwitchListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
      value: value,
      onChanged: on,
    );

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            person.displayName,
            style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 4),
          const Text('Emergency card', style: TextStyle(color: onboardMuted)),
          const SectionLabel('What it shows'),
          Card(
            child: Column(
              children: [
                toggle('Blood group', 'Shown large.', o.bloodGroup, (v) => change(o.copyWith(bloodGroup: v))),
                const Divider(height: 1),
                toggle('Allergies', 'Names only. If none are added, it says so.', o.allergies, (v) => change(o.copyWith(allergies: v))),
                const Divider(height: 1),
                toggle('Medicines', 'Current medicines. Off unless you turn it on.', o.medicines, (v) => change(o.copyWith(medicines: v))),
                const Divider(height: 1),
                toggle('Dial button', 'Opens the dialer with the number filled in. You press the call button there.', o.dial, (v) => change(o.copyWith(dial: v))),
              ],
            ),
          ),
          if (o.dial) ...[
            const SectionLabel('Who to dial'),
            if (contacts.isEmpty)
              const Text('No emergency contact added yet. Add one on this person\'s profile, and the button will appear.')
            else
              Card(
                child: RadioGroup<int>(
                  groupValue: o.dialContact.clamp(0, contacts.length - 1),
                  onChanged: (v) => change(o.copyWith(dialContact: v)),
                  child: Column(
                    children: [
                      for (var i = 0; i < contacts.length; i++)
                        RadioListTile<int>(
                          value: i,
                          title: Text(contacts[i].name, style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text([
                            if (contacts[i].relationship != null) contacts[i].relationship!,
                            contacts[i].phone,
                          ].join(' · ')),
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SectionLabel('Add to home screen'),
          for (final (kind, title, sub) in const [
            ('card', 'Emergency card', 'Name, blood group, allergies and a dial button. The full card.'),
            ('dial', 'Dial button', 'One big button that opens the dialer. Good for a phone used by an older person.'),
            ('blood', 'Blood group and allergies', 'Just those two, for a quick glance.'),
          ])
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
                subtitle: Text(sub),
                trailing: const Icon(Icons.add_circle_outline),
                onTap: () async {
                  final asked = await AmruthamWidgets.pinCard(person.id.value, kind: kind);
                  if (!context.mounted || asked) return;
                  await showDialog<void>(
                    context: context,
                    builder: (dialog) => AlertDialog(
                      title: const Text('Add it from your home screen'),
                      content: Text(
                        'Your phone can\'t be asked to add it from here. Touch and '
                        'hold an empty spot on your home screen, choose Widgets, '
                        'then Amrutham, and pick "$title". You\'ll choose who it is for.',
                      ),
                      actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: const Text('OK'))],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
