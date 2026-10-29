import 'package:flutter/material.dart';

import 'app_style.dart';
import 'family_screen.dart';
import 'records_screen.dart';
import 'today_screen.dart';

/// The four tabs from the Doop frames. Records and Learn aren't built yet,
/// so they say so rather than pretending.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    (Icons.schedule, 'Today'),
    (Icons.people_outline, 'Family'),
    (Icons.description_outlined, 'Records'),
    (Icons.menu_book_outlined, 'Learn'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [
          TodayScreen(),
          FamilyScreen(),
          RecordsScreen(),
          _ComingSoon('Learn'),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _index = i),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _tabs[i].$1,
                            color: i == _index ? onboardInk : onboardMuted,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _tabs[i].$2,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: i == _index
                                  ? FontWeight.w800
                                  : FontWeight.w500,
                              color: i == _index ? onboardInk : onboardMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              "Not built yet. It's in the designs and coming soon.",
              style: TextStyle(fontSize: 16, color: onboardMuted),
            ),
          ],
        ),
      ),
    );
  }
}
