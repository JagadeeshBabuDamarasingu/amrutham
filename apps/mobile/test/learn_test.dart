import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/learn/learn_content.dart';
import 'package:amrutham/ui/app_shell.dart';

void main() {
  test('guides have unique ids, and none claims a review nobody did', () {
    final ids = allGuides.map((g) => g.id).toSet();
    expect(ids, hasLength(allGuides.length));
    for (final g in allGuides) {
      expect(g.blocks, isNotEmpty, reason: g.id);
      // Review dates may only be set by a person who reviewed the guide.
      expect(g.reviewedOn, isNull, reason: '${g.id} must stay Draft until reviewed');
      expect(g.isDraft, isTrue);
    }
  });

  test('every clinical guide links to an official source and carries the disclaimer', () {
    for (final g in clinicalGuides) {
      if (g.id == 'privacy-sensitive') continue; // describes Amrutham itself
      final hasSource = g.blocks.any((b) => b is LearnSourceLink) ||
          g.blocks.any((b) => b is LearnTabs || b is LearnHelpLink);
      expect(hasSource, isTrue, reason: '${g.id} needs a source link or the help page');
      expect(g.footer, isNotNull, reason: g.id);
      expect(g.footer!.toLowerCase(), contains('not medical advice'), reason: g.id);
    }
  });

  test('crisis guides lead people to help, and no guide gives a dose or a vaccine schedule', () {
    final crisis = allGuides.firstWhere((g) => g.id == 'thoughts-of-ending-life');
    expect(crisis.blocks.any((b) => b is LearnHelpLink), isTrue);
    final dose = RegExp(r'\b\d+\s?(mg|ml|mcg)\b|\bweeks? old\b|\bmonths? old\b', caseSensitive: false);
    String texts(LearnBlock b) => switch (b) {
      LearnParagraph(:final text) => text,
      LearnNote(:final text) => text,
      LearnList(:final items) => items.join(' '),
      LearnBullets(:final items) => items.map((e) => e.$2).join(' '),
      _ => '',
    };
    for (final g in allGuides) {
      for (final b in g.blocks) {
        expect(dose.hasMatch(texts(b)), isFalse, reason: '${g.id}: ${texts(b)}');
      }
    }
  });

  test('overdue is judged from the next-due date', () {
    final overdue = LearnGuide(
      id: 'x',
      category: 'c',
      title: 't',
      summary: 's',
      blocks: const [],
      reviewedOn: DateTime(2020),
      nextReviewDue: DateTime(2021),
    );
    expect(overdue.reviewOverdue, isTrue);
    expect(overdue.isDraft, isFalse);
  });

  test('no guide states a rupee amount or a percentage as a fact', () {
    final numbers = RegExp(r'₹|\d+\s?%|\blakh\b|\bcrore\b', caseSensitive: false);
    for (final g in allGuides) {
      for (final b in g.blocks) {
        final text = switch (b) {
          LearnParagraph(:final text) => text,
          LearnNote(:final text) => text,
          LearnInfoCard(:final body) => body,
          _ => '',
        };
        expect(numbers.hasMatch(text), isFalse, reason: '${g.id}: "$text"');
      }
    }
  });

  test('the daily tip rotates over the year and never repeats back to back', () {
    final tips = {
      for (var d = 0; d < dailyTips.length; d++) tipForDay(DateTime(2026, 1, 1 + d)),
    };
    expect(tips, hasLength(dailyTips.length));
    for (final tip in dailyTips) {
      // F12 rules: no scare wording, no named disease.
      expect(tip.toLowerCase(), isNot(contains('cancer')));
      expect(tip.toLowerCase(), isNot(contains('die')));
    }
  });
}
