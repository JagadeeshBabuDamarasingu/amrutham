import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../about/app_info.dart';
import 'app_style.dart';
import 'problem_report.dart';

Future<void> _open(BuildContext context, Uri uri) async {
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Couldn't open that link.")));
  }
}

Widget _title(String text, [String? lede]) => Padding(
  padding: const EdgeInsets.only(bottom: 6),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(text, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
      if (lede != null) ...[
        const SizedBox(height: 8),
        Text(lede, style: const TextStyle(color: onboardMuted, height: 1.45)),
      ],
    ],
  ),
);

/// Settings > Help > About Amrutham (Doop frame 15a).
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _promises = [
    (Icons.all_inclusive, 'Free, forever', 'No price, no ads, no paywalled features. Your data is never sold.'),
    (Icons.code, 'Open source', 'The code is public under the GPL-3.0 licence. Read it, run it, change it.'),
    (Icons.visibility_outlined, "Check, don't trust", 'No account, no analytics, no server of ours. You can confirm that in the code.'),
    (Icons.info_outline, 'Not medical advice', 'Talk to a doctor about your health. In an emergency, call your local emergency number.'),
  ];

  @override
  Widget build(BuildContext context) {
    Widget row(String title, String sub, VoidCallback onTap, {IconData trailing = Icons.chevron_right}) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
      trailing: Icon(trailing),
      onTap: onTap,
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            decoration: BoxDecoration(color: onboardInk, borderRadius: BorderRadius.circular(26)),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 32,
                  backgroundColor: onboardAmber,
                  child: Icon(Icons.favorite, size: 30, color: Color(0xFF2A1D00)),
                ),
                const SizedBox(height: 14),
                const Text('Amrutham', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6)),
                const SizedBox(height: 6),
                const Text(
                  'A free, private health record for your whole family.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFCFE0D8), height: 1.45),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Text('Version $appVersion · build $appBuild', style: TextStyle(color: Color(0xFF9FC0B2), fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SectionLabel('Our vision'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(aboutVision, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, height: 1.28, letterSpacing: -0.3)),
            ),
          ),
          const SectionLabel('Our mission'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(aboutMission, style: TextStyle(fontSize: 14.5, height: 1.55)),
            ),
          ),
          const SectionLabel('What we promise'),
          Card(
            child: Column(
              children: [
                for (var i = 0; i < _promises.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                    leading: CircleAvatar(
                      radius: 17,
                      backgroundColor: const Color(0xFFD5E5DD),
                      child: Icon(_promises[i].$1, size: 19, color: onboardInk),
                    ),
                    title: Text(_promises[i].$2, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text(_promises[i].$3),
                  ),
                ],
              ],
            ),
          ),
          const SectionLabel('More'),
          Card(
            child: Column(
              children: [
                row('Credits and licences', 'The software and fonts Amrutham is built on', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreditsScreen()))),
                const Divider(height: 1),
                row('Contact us', 'Questions, ideas, or something wrong', () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactScreen()))),
                const Divider(height: 1),
                row('Source code', 'github.com/JagadeeshBabuDamarasingu/amrutham', () => _open(context, Uri.parse(sourceUrl)), trailing: Icons.north_east),
                const Divider(height: 1),
                row('Privacy policy', 'amrutham.app/privacy', () => _open(context, Uri.parse(privacyUrl)), trailing: Icons.north_east),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Amrutham comes from the Sanskrit amrita, the nectar of life.\nMade for families everywhere.',
            textAlign: TextAlign.center,
            style: TextStyle(color: onboardMuted, fontSize: 12.5, height: 1.55),
          ),
        ],
      ),
    );
  }
}

/// Frame 15b.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _title('Credits and licences', 'Amrutham stands on the work of many people who share their software for free. Thank you.'),
          for (final group in credits) ...[
            SectionLabel(group.title),
            Card(
              child: Column(
                children: [
                  for (var i = 0; i < group.items.length; i++) ...[
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                      title: Text(group.items[i].name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                      subtitle: Text(group.items[i].what),
                      trailing: group.items[i].licence == null
                          ? null
                          : Container(
                              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(color: const Color(0xFFD5E5DD), borderRadius: BorderRadius.circular(99)),
                              child: Text(group.items[i].licence!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: onboardInk)),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SectionLabel('Health guides'),
          const Card(
            child: ListTile(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text('Sources are named on each guide', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: Text('Learn guides cite the public health bodies and journals they were written from. Open a guide and tap "About this content".'),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: const Text('Full licence texts', style: TextStyle(fontWeight: FontWeight.w800)),
              subtitle: const Text('Every package and its licence, in full'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showLicensePage(context: context, applicationName: 'Amrutham', applicationVersion: '$appVersion ($appBuild)'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 14, 12, 0),
            child: Text(
              'Amrutham itself is free software under the GPL-3.0 licence. The Realm database keeps its own Apache-2.0 licence.',
              style: TextStyle(color: onboardMuted, fontSize: 12.5, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Frame 15c.
class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget row(IconData icon, String title, String sub, VoidCallback onTap, {IconData trailing = Icons.chevron_right}) => ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        radius: 19,
        backgroundColor: const Color(0xFFD5E5DD),
        child: Icon(icon, size: 20, color: onboardInk),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(sub),
      trailing: Icon(trailing),
      onTap: onTap,
    );
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          _title('Contact us', 'Amrutham is a small, independent project. A person reads every message.'),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                row(Icons.mail_outline, 'Email us', reportAddress, () => _open(context, Uri(scheme: 'mailto', path: reportAddress, queryParameters: {'subject': 'Amrutham $appVersion'}))),
                const Divider(height: 1),
                row(Icons.warning_amber_rounded, 'Send a problem report', 'See what crashed, then choose whether to send it', () => showProblemReport(context)),
                const Divider(height: 1),
                row(Icons.bug_report_outlined, 'Report on GitHub', 'For bugs and ideas you want others to see', () => _open(context, Uri.parse(issuesUrl)), trailing: Icons.north_east),
              ],
            ),
          ),
          const SectionLabel('Before you write'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: "Please don't send health details by email. ", style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: "A problem report never holds your records, names or messages, and we don't need them to help."),
                  ])),
                  SizedBox(height: 10),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: "We can't give medical advice. ", style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: 'For a health question, ask a doctor. In an emergency, call your local emergency number.'),
                  ])),
                  SizedBox(height: 10),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: 'Lost your recovery code? ', style: TextStyle(fontWeight: FontWeight.w800)),
                    TextSpan(text: "We can't recover it for you. Nobody but you holds it, and that is on purpose."),
                  ])),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 16, 12, 0),
            child: Text(
              'Amrutham is free and built with limited time, so a reply can take a while.',
              style: TextStyle(color: onboardMuted, fontSize: 12.5, height: 1.55),
            ),
          ),
        ],
      ),
    );
  }
}
