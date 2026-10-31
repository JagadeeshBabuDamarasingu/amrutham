// Android only lets a home screen widget use a short list of view types. Any
// other tag (even a plain <View>) makes the phone say "Can't load widget", and
// no Dart test can see it, so this reads the layout file itself.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the emergency card layout uses only view types a widget may inflate', () {
    // From RemoteViews' @RemoteView allow-list.
    const allowed = {
      'FrameLayout', 'LinearLayout', 'RelativeLayout', 'GridLayout',
      'AdapterViewFlipper', 'GridView', 'ListView', 'StackView', 'ViewFlipper',
      'AnalogClock', 'Button', 'Chronometer', 'ImageButton', 'ImageView',
      'ProgressBar', 'TextClock', 'TextView', 'CheckBox', 'RadioButton',
      'RadioGroup', 'Switch',
    };
    for (final name in [
      'amrutham_emergency_widget',
      'amrutham_emergency_widget_large',
      'amrutham_dial_widget',
      'amrutham_blood_widget',
    ]) {
      final xml = File(
        'plugins/amrutham_widgets/android/src/main/res/layout/$name.xml',
      ).readAsStringSync();
      final tags = RegExp(r'<([A-Za-z][A-Za-z0-9.]*)').allMatches(xml).map((m) => m[1]!).toSet();
      expect(tags.difference(allowed), isEmpty, reason: '$name: not allowed in a widget');
    }
  });
}
