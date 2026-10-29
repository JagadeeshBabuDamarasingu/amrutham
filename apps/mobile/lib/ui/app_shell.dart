import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

import 'app_style.dart';
import 'strings.dart';
import 'family_screen.dart';
import 'learn_screen.dart';
import 'records_screen.dart';
import 'today_screen.dart';

/// The four tabs from the Doop frames.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

/// One line per day, the same for everyone and never based on anyone's
/// records. No disease named, no scare wording. Tapping opens Learn.
const dailyTips = [
  'Finding a problem early often makes it easier to treat.',
  'Feeling well? A routine check-up is still worth it.',
  'Many conditions show no symptoms at first. Screening can find them early.',
  "Noticed a change that lasts? Don't wait. Ask a doctor.",
  'Bring your records to every visit. They help every doctor you see.',
  'Write your questions down before an appointment.',
];

String tipForDay(DateTime d) =>
    dailyTips[d.difference(DateTime(d.year)).inDays % dailyTips.length];

class _AppShellState extends ConsumerState<AppShell> {
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
          LearnScreen(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_index == 0 && !(ref.watch(tipsHiddenProvider).valueOrNull ?? false))
              GestureDetector(
                onTap: () => setState(() => _index = 3),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAEFD0),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(radius: 4, backgroundColor: onboardAmber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          tipForDay(DateTime.now()),
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF3D2E00)),
                        ),
                      ),
                      const Text('Learn ›', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5A4300))),
                    ],
                  ),
                ),
              ),
            Container(
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
                            tr(context, _tabs[i].$2),
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
          ],
        ),
      ),
    );
  }
}
