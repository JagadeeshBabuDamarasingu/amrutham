import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/model/ids.dart';
import 'package:amrutham/backup/readable_copy.dart';
import 'package:amrutham/model/person.dart';

void main() {
  test('a readable copy has a summary and a table per person, no code needed', () {
    final p = PersonProfile(
      id: const PersonId('p1'),
      displayName: 'Appa',
      relationship: RelationshipType.parent,
      bloodGroup: 'O positive',
      createdAt: DateTime(2024),
    );
    final files = readableCopy([PersonData(p)], [], [p]);
    expect(files.keys, containsAll(['Appa-summary.txt', 'Appa-measurements.csv']));
    expect(files['Appa-summary.txt'], contains('Blood group: O positive'));
    expect(readableCopy([], [], [p]), isEmpty);
  });
}
