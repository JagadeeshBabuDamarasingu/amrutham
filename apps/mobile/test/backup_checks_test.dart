import 'package:flutter_test/flutter_test.dart';
import 'package:amrutham/ui/backup_checks.dart';

void main() {
  test('recovery sheet has blanks for the code and no code or health data', () {
    final html = recoverySheetHtml();
    expect(html, contains('My recovery code'));
    expect(html, contains('____ ____'));
    expect(html, isNot(contains('Allerg')));
  });
}
