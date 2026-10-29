import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../learn/learn_content.dart';
import 'add_record_screen.dart';
import 'app_style.dart';
import 'expenses_screen.dart';
import 'log_measurement_screen.dart' show monthNames;
import 'settings_screen.dart';

String _monthYear(DateTime d) => '${monthNames[d.month - 1]} ${d.year}';

const _hubIcons = {
  LearnHub.money: Icons.account_balance_wallet_outlined,
  LearnHub.sexualHealth: Icons.favorite_border,
  LearnHub.growingUp: Icons.family_restroom,
  LearnHub.mentalWellbeing: Icons.self_improvement,
};

Future<void> _openUrl(BuildContext context, String url) async {
  final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open $url")));
  }
}

void _push(BuildContext context, Widget screen) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

/// Short guides that explain how things work. No feed, no recommendations,
/// and nothing you read is saved or shown to anyone.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Learn',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8),
                ),
              ),
              FilledButton(
                onPressed: () => _push(context, const HelpNowScreen()),
                style: FilledButton.styleFrom(
                  backgroundColor: onboardAmber,
                  foregroundColor: const Color(0xFF2A1D00),
                ),
                child: const Text('Help now'),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: () => _push(context, const SettingsScreen()),
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
              ),
            ],
          ),
          const Text(
            'Short guides that explain how things work. Not advice about you.',
            style: TextStyle(color: onboardMuted),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => _push(context, const AboutContentScreen()),
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(24)),
              child: const Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WRITTEN FROM PUBLIC GUIDANCE',
                          style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 11, letterSpacing: 1),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Every guide links to its official source.',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  Text('About ›', style: TextStyle(color: onboardAmber, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ),
          const SectionLabel('Topics'),
          for (final hub in LearnHub.values)
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => _push(context, HubScreen(hub: hub)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD5E4DC),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(_hubIcons[hub], color: onboardInk),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hub.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                            Text(hub.blurb, style: const TextStyle(color: onboardMuted, fontSize: 13)),
                            const SizedBox(height: 4),
                            Text(
                              '${allGuides.where((g) => g.hub == hub).length} guides',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: onboardMuted),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Text(
            'No feed, no recommendations. What you read is never saved or shown to anyone.',
            textAlign: TextAlign.center,
            style: TextStyle(color: onboardMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// One topic area: privacy banner (for sensitive ones), a callout, its guides.
class HubScreen extends StatelessWidget {
  const HubScreen({super.key, required this.hub});

  final LearnHub hub;

  @override
  Widget build(BuildContext context) {
    final guides = allGuides.where((g) => g.hub == hub).toList();
    final children = <Widget>[];
    String? group;
    for (final g in guides) {
      if (hub == LearnHub.money && g.category != group) {
        group = g.category;
        children.add(SectionLabel(g.category));
      }
      children.add(
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _push(context, GuideScreen(guide: g)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(g.summary, style: const TextStyle(color: onboardMuted)),
                  const SizedBox(height: 10),
                  ReviewPill(guide: g),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget? callout;
    switch (hub) {
      case LearnHub.sexualHealth:
        callout = _HubCallout(
          kicker: 'KNOW THIS',
          title: "A condom lowers the risk a lot. It doesn't remove it.",
          action: 'See all key facts ›',
          onTap: () => _push(context, GuideScreen(guide: allGuides.firstWhere((g) => g.id == 'key-facts'))),
        );
      case LearnHub.growingUp:
        callout = const _HubCallout(
          kicker: 'GET HELP STRAIGHT AWAY',
          title: 'In pregnancy: heavy bleeding, a severe headache, or much less baby movement.',
        );
      case LearnHub.mentalWellbeing:
        callout = _HubCallout(
          kicker: 'NEED HELP NOW',
          title: 'Thinking about harming yourself, or worried about someone?',
          action: 'Open help now ›',
          onTap: () => _push(context, const HelpNowScreen()),
        );
      case LearnHub.money:
        callout = null;
    }

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(hub.title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 4),
          Text(hub.blurb, style: const TextStyle(color: onboardMuted)),
          const SizedBox(height: 16),
          if (hub.isPrivate) ...[
            InkWell(
              onTap: () => _push(context, const SettingsScreen()),
              borderRadius: BorderRadius.circular(20),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(20)),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline, color: onboardAmber),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Private here', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                          Text(
                            'What you read is never saved or shown to anyone.',
                            style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Text('Settings ›', style: TextStyle(color: onboardAmber, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          ?callout,
          if (hub != LearnHub.money) const SectionLabel('Guides'),
          ...children,
        ],
      ),
    );
  }
}

class _HubCallout extends StatelessWidget {
  const _HubCallout({required this.kicker, required this.title, this.action, this.onTap});

  final String kicker;
  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: onboardAmber, borderRadius: BorderRadius.circular(24)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 9, backgroundColor: Color(0xFF2A1D00), child: Text('!', style: TextStyle(fontSize: 11, color: onboardAmber, fontWeight: FontWeight.w900))),
                const SizedBox(width: 8),
                Text(kicker, style: const TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: Color(0xFF2A1D00))),
              ],
            ),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 21, height: 1.2, fontWeight: FontWeight.w900, color: Color(0xFF2A1D00))),
            if (action != null) ...[
              const SizedBox(height: 10),
              Text(action!, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2A1D00))),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Reviewed Aug 2026 · Next due Aug 2029", "Review overdue", or "Draft".
class ReviewPill extends StatelessWidget {
  const ReviewPill({super.key, required this.guide});

  final LearnGuide guide;

  @override
  Widget build(BuildContext context) {
    final (label, bg) = guide.isDraft
        ? ('Draft · not yet reviewed', const Color(0xFFFAEFD0))
        : guide.reviewOverdue
        ? ('Review overdue', const Color(0xFFFAEFD0))
        : ('Reviewed ${_monthYear(guide.reviewedOn!)}', const Color(0xFFD5E4DC));
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        if (guide.nextReviewDue != null) ...[
          const SizedBox(width: 8),
          Text(
            '${guide.reviewOverdue ? 'Was due' : 'Next due'} ${_monthYear(guide.nextReviewDue!)}',
            style: const TextStyle(fontSize: 12, color: onboardMuted),
          ),
        ],
      ],
    );
  }
}

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key, required this.guide});

  final LearnGuide guide;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Text(
            guide.category.toUpperCase(),
            style: const TextStyle(fontSize: 12, letterSpacing: 1, fontWeight: FontWeight.w700, color: onboardMuted),
          ),
          const SizedBox(height: 6),
          Text(
            guide.title,
            style: const TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w800, letterSpacing: -0.8),
          ),
          const SizedBox(height: 12),
          ReviewPill(guide: guide),
          const SizedBox(height: 12),
          for (final b in guide.blocks) BlockView(block: b),
          if (guide.footer != null) ...[
            const SizedBox(height: 16),
            Text(guide.footer!, style: const TextStyle(color: onboardMuted, height: 1.4)),
          ],
        ],
      ),
    );
  }
}

class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block});

  final LearnBlock block;

  Widget _card(List<Widget> children) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    ),
  );

  Widget _bullet(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 9, right: 12),
          child: CircleAvatar(radius: 3, backgroundColor: onboardInk),
        ),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.45))),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      LearnParagraph(:final text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(text, style: const TextStyle(fontSize: 17, height: 1.5)),
      ),
      LearnHeading(:final text) => Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      ),
      LearnBullets(:final items) => Column(
        children: [
          for (final (lead, text) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 9, right: 12),
                    child: CircleAvatar(radius: 3, backgroundColor: onboardInk),
                  ),
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          if (lead != null) TextSpan(text: '$lead: ', style: const TextStyle(fontWeight: FontWeight.w800)),
                          TextSpan(text: text),
                        ],
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.45),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      LearnList(:final title, :final items) => _card([
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        for (final i in items) _bullet(i),
      ]),
      LearnChecklist(:final label, :final items) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel(label),
          Card(
            child: Column(
              children: [
                for (final i in items)
                  ListTile(
                    dense: true,
                    leading: const CircleAvatar(radius: 4, backgroundColor: onboardAmber),
                    title: Text(i, style: const TextStyle(fontSize: 16)),
                  ),
              ],
            ),
          ),
        ],
      ),
      LearnInfoCard(:final title, :final body, :final linkLabel, :final url) => _card([
        Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(body, style: const TextStyle(color: onboardMuted, height: 1.4)),
        const Divider(height: 24),
        InkWell(
          onTap: url == null ? null : () => _openUrl(context, url),
          child: Text(url == null ? linkLabel : '$linkLabel ›', style: const TextStyle(fontWeight: FontWeight.w800)),
        ),
      ]),
      LearnCallout(:final tone, :final title, :final body) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: tone == CalloutTone.know ? onboardAmber : onboardInk,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tone == CalloutTone.know ? 'KNOW THIS' : 'GOOD NEWS',
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1,
                fontWeight: FontWeight.w800,
                color: tone == CalloutTone.know ? const Color(0xFF2A1D00) : onboardAmber,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 21,
                height: 1.2,
                fontWeight: FontWeight.w900,
                color: tone == CalloutTone.know ? const Color(0xFF2A1D00) : Colors.white,
              ),
            ),
            if (body != null) ...[
              const SizedBox(height: 6),
              Text(
                body,
                style: TextStyle(color: tone == CalloutTone.know ? const Color(0xFF2A1D00) : const Color(0xFFB8D0C5)),
              ),
            ],
          ],
        ),
      ),
      LearnMythFact(:final myth, :final fact) => Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), color: Colors.white),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              color: const Color(0xFFECEFED),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MYTH', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: onboardMuted)),
                  Text(myth, style: const TextStyle(decoration: TextDecoration.lineThrough, color: onboardMuted)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FACT', style: TextStyle(fontSize: 11, letterSpacing: 1, fontWeight: FontWeight.w800, color: onboardMuted)),
                  Text(fact, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1.25)),
                ],
              ),
            ),
          ],
        ),
      ),
      LearnTabs(:final tabs) => _TabsView(tabs: tabs),
      LearnHelpLink() => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          onTap: () => _push(context, const HelpNowScreen()),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: onboardAmber, borderRadius: BorderRadius.circular(24)),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Get help now', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF2A1D00))),
                      Text('Free, confidential, and you can call right away', style: TextStyle(color: Color(0xFF2A1D00))),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Color(0xFF2A1D00)),
              ],
            ),
          ),
        ),
      ),
      LearnSourceLink(:final label, :final host, :final url) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          onTap: () => _openUrl(context, url),
          borderRadius: BorderRadius.circular(24),
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(24)),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: const TextStyle(color: Color(0xFFB8D0C5), fontSize: 11, letterSpacing: 1)),
                      Text(host, style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                      const Text(
                        'Official source · link not yet verified',
                        style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.north_east, color: onboardAmber),
              ],
            ),
          ),
        ),
      ),
      LearnAppLink(:final title, :final subtitle, :final action) => Card(
        child: ListTile(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _push(
            context,
            switch (action) {
              LearnAction.expenses => const ExpensesScreen(),
              LearnAction.addRecord => const AddRecordScreen(),
            },
          ),
        ),
      ),
      LearnNote(:final text) => Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFFFAEFD0), borderRadius: BorderRadius.circular(20)),
        child: Text(text, style: const TextStyle(color: Color(0xFF5A4300), height: 1.4)),
      ),
    };
  }
}

class _TabsView extends StatefulWidget {
  const _TabsView({required this.tabs});

  final List<(String, List<LearnBlock>)> tabs;

  @override
  State<_TabsView> createState() => _TabsViewState();
}

class _TabsViewState extends State<_TabsView> {
  int _i = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SegmentedButton<int>(
          showSelectedIcon: false,
          segments: [for (var i = 0; i < widget.tabs.length; i++) ButtonSegment(value: i, label: Text(widget.tabs[i].$1))],
          selected: {_i},
          onSelectionChanged: (s) => setState(() => _i = s.first),
        ),
        const SizedBox(height: 8),
        for (final b in widget.tabs[_i].$2) BlockView(block: b),
      ],
    );
  }
}

/// Crisis page: calls with one tap, plain wording, works with no connection
/// (the numbers are in the app, not fetched).
class HelpNowScreen extends StatelessWidget {
  const HelpNowScreen({super.key});

  // Listed on mohfw.gov.in per the design, but NOT yet verified by a person
  // for this release (see product_priorities memory). Confirm before release.
  static const _teleManas = '14416';
  static const _emergency = '112';

  Future<void> _call(BuildContext context, String number) async {
    final ok = await launchUrl(Uri(scheme: 'tel', path: number));
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please dial $number')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text(
            "You're not alone. Help is available now.",
            style: TextStyle(fontSize: 32, height: 1.1, fontWeight: FontWeight.w900, letterSpacing: -0.8),
          ),
          const SizedBox(height: 12),
          const Text(
            "If you're thinking of harming yourself, or you're worried about someone else, please reach out right now.",
            style: TextStyle(fontSize: 17, height: 1.45),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(28)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TALK TO SOMEONE NOW', style: TextStyle(color: Color(0xFFB8D0C5), fontSize: 11, letterSpacing: 1)),
                const SizedBox(height: 4),
                const Text('Tele-MANAS', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                const Text(
                  'A national mental health helpline. Free and confidential.',
                  style: TextStyle(color: Color(0xFFB8D0C5)),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: () => _call(context, _teleManas),
                  style: FilledButton.styleFrom(
                    backgroundColor: onboardAmber,
                    foregroundColor: const Color(0xFF2A1D00),
                    minimumSize: const Size.fromHeight(56),
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  icon: const Icon(Icons.call),
                  label: const Text('Call $_teleManas'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('In danger right now', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                        Text('Call your local emergency number.', style: TextStyle(color: onboardMuted)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: () => _call(context, _emergency),
                    style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9B3B2A)),
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text(_emergency),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: const Color(0xFFE3ECE7), borderRadius: BorderRadius.circular(24)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('While you wait', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                SizedBox(height: 8),
                _Dot('Stay with someone you trust, or ask them to come to you.'),
                _Dot('Move away from anything you could use to hurt yourself.'),
                _Dot('Breathe slowly: in for four, out for six.'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Numbers are listed on mohfw.gov.in. They have not yet been verified '
            'by the Amrutham maintainers, so check them there. This page works '
            'without an internet connection.',
            style: TextStyle(color: onboardMuted, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 8, right: 10),
            child: CircleAvatar(radius: 3, backgroundColor: onboardInk),
          ),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 16, height: 1.4))),
        ],
      ),
    );
  }
}

class AboutContentScreen extends StatelessWidget {
  const AboutContentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget item(IconData icon, Color color, String title, String body) => ListTile(
      leading: CircleAvatar(
        radius: 14,
        backgroundColor: color.withValues(alpha: 0.18),
        child: Icon(icon, size: 16, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(body),
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          const Text('About this content', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
          const SizedBox(height: 4),
          const Text('Where it comes from, and what it will never be.', style: TextStyle(color: onboardMuted)),
          const SectionLabel('How it is kept honest'),
          Card(
            child: Column(
              children: [
                item(Icons.check, onboardInk, 'Review dates on everything',
                    'Every guide shows when it was reviewed and when it is next due. Guides not yet reviewed say Draft. Overdue ones are flagged.'),
                item(Icons.check, onboardInk, 'Concepts inside, facts by link',
                    'Guides explain how things work. Current amounts, schedules and rules are always a link to the official site.'),
                item(Icons.check, onboardInk, 'Links are checked each release',
                    'Broken links are fixed before an update ships.'),
              ],
            ),
          ),
          const SectionLabel('What it will never do'),
          Card(
            child: Column(
              children: [
                item(Icons.close, const Color(0xFF9B3B2A), 'Carry posts by individual doctors',
                    'No author badges, no "doctor-approved" labels.'),
                item(Icons.close, const Color(0xFF9B3B2A), 'Recommend, rank or track',
                    'No "for you" suggestions, no insurer named, no reading history kept.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
