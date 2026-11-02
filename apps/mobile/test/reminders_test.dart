import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/ui/backup_recovery_screen.dart';

void main() {
  final now = DateTime(2026, 11, 10);
  test('a folder copy is flagged after a week, not before, and never without a folder', () {
    expect(staleFolderNote(true, DateTime(2026, 11, 4), now), isNull);
    expect(staleFolderNote(true, DateTime(2026, 11, 3), now), contains('7 days old'));
    expect(staleFolderNote(false, DateTime(2026, 1, 1), now), isNull);
    expect(staleFolderNote(true, null, now), isNull);
  });
  test('a readable copy is flagged for deletion after a week', () {
    expect(readableCopyNote(null, now), isNull);
    expect(readableCopyNote(DateTime(2026, 11, 8), now), isNull);
    expect(readableCopyNote(DateTime(2026, 11, 1), now), contains('9 days ago'));
  });
}
