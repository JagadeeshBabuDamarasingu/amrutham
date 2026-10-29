import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/learn/learn_content.dart';
import 'package:amrutham/ui/app_shell.dart';

void main() {
  test('guides have unique ids, and none claims a review nobody did', () {
    final ids = learnGuides.map((g) => g.id).toSet();
    expect(ids, hasLength(learnGuides.length));
    for (final g in learnGuides) {
      expect(g.blocks, isNotEmpty, reason: g.id);
      // Review dates may only be set by a person who reviewed the guide.
      expect(g.reviewedOn, isNull, reason: '${g.id} must stay Draft until reviewed');
      expect(g.isDraft, isTrue);
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
    for (final g in learnGuides) {
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
