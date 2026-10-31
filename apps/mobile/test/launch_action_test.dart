// Where a widget tap or an app-icon shortcut lands.

import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/model/ids.dart';
import 'package:amrutham/quick_access/launch_action.dart';

void main() {
  const appa = PersonId('appa');
  const amma = PersonId('amma');
  const living = [appa, amma];

  LaunchTarget? go(String action, {String? person, PersonId? selected, List<PersonId> who = living}) =>
      resolveLaunch(
        {'action': action, 'personId': ?person},
        living: who,
        selected: selected,
      );

  test('a widget opens the card of the person it names', () {
    expect(go('emergency', person: 'amma'), const LaunchTarget(LaunchKind.emergencyCard, amma));
  });

  test('a shortcut, which names nobody, uses the selected person, else the first', () {
    expect(go('emergency', selected: amma), const LaunchTarget(LaunchKind.emergencyCard, amma));
    expect(go('log-reading'), const LaunchTarget(LaunchKind.logReading, appa));
    expect(go('add-record', selected: amma), const LaunchTarget(LaunchKind.addRecord, amma));
  });

  test('a person who is gone or deceased is never opened', () {
    expect(go('emergency', person: 'ghost'), const LaunchTarget(LaunchKind.emergencyCard, appa));
    expect(go('emergency', person: 'amma', who: const [appa]), const LaunchTarget(LaunchKind.emergencyCard, appa));
    expect(go('emergency', selected: amma, who: const [appa]), const LaunchTarget(LaunchKind.emergencyCard, appa));
  });

  test('with nobody to show, the person-based shortcuts go nowhere', () {
    for (final a in ['emergency', 'log-reading', 'add-record']) {
      expect(go(a, who: const []), isNull);
    }
  });

  test('next dose needs no person, and unknown actions are ignored', () {
    expect(go('next-dose', who: const []), const LaunchTarget(LaunchKind.nextDose));
    expect(go('format-the-phone'), isNull);
    expect(resolveLaunch(const {}, living: living), isNull);
  });
}
