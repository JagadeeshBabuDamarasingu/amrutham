import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../learn/learn_content.dart';
import 'add_record_screen.dart';
import 'app_style.dart';
import 'expenses_screen.dart';
import 'log_measurement_screen.dart' show monthNames;
import 'settings_screen.dart';

String _monthYear(DateTime d) => '${monthNames[d.month - 1]} ${d.year}';

/// Short guides that explain how things work. No feed, no recommendations,
/// and nothing you read is saved or shown to anyone.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final categories = {for (final g in learnGuides) g.category}.toList();
    final shown = [
      for (final g in learnGuides)
        if (_category == null || g.category == _category) g,
    ];
    final children = <Widget>[];
    String? group;
    for (final g in shown) {
      if (g.category != group) {
        group = g.category;
        children.add(SectionLabel(g.category));
      }
      children.add(
        Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => GuideScreen(guide: g)),
            ),
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
              IconButton.filledTonal(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
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
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AboutContentScreen()),
            ),
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
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('All · ${learnGuides.length}'),
                    selected: _category == null,
                    onSelected: (_) => setState(() => _category = null),
                  ),
                ),
                for (final c in categories)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c),
                      selected: _category == c,
                      onSelected: (_) => setState(() => _category = c),
                    ),
                  ),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 20),
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

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key, required this.guide});

  final LearnGuide guide;

  Future<void> _open(BuildContext context, String url) async {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open $url")));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget block(LearnBlock b) => switch (b) {
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
                  const Padding(padding: EdgeInsets.only(top: 9, right: 12), child: CircleAvatar(radius: 3, backgroundColor: onboardInk)),
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
      LearnInfoCard(:final title, :final body, :final linkLabel, :final url) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(body, style: const TextStyle(color: onboardMuted, height: 1.4)),
              const Divider(height: 24),
              InkWell(
                onTap: url == null ? null : () => _open(context, url),
                child: Text(
                  url == null ? linkLabel : '$linkLabel ›',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ),
      LearnSourceLink(:final label, :final host, :final url) => Padding(
        padding: const EdgeInsets.only(top: 12),
        child: InkWell(
          onTap: () => _open(context, url),
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
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => switch (action) {
                LearnAction.expenses => const ExpensesScreen(),
                LearnAction.addRecord => const AddRecordScreen(),
              },
            ),
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
          for (final b in guide.blocks) block(b),
          if (guide.footer != null) ...[
            const SizedBox(height: 16),
            Text(guide.footer!, style: const TextStyle(color: onboardMuted, height: 1.4)),
          ],
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
                    'Guides explain how things work. Current amounts and rules are always a link to the official site.'),
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
