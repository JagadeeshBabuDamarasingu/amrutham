import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amrutham/ui/strings.dart';

void main() {
  testWidgets('chrome follows the app language and falls back to English', (tester) async {
    late BuildContext ctx;
    Future<void> pump(String lang) => tester.pumpWidget(
      MaterialApp(
        locale: Locale(lang),
        supportedLocales: const [Locale('en'), Locale('hi')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(builder: (c) { ctx = c; return const SizedBox(); }),
      ),
    );
    await pump('hi');
    expect(tr(ctx, 'Today'), 'आज');
    expect(tr(ctx, 'Something untranslated'), 'Something untranslated');
    await pump('en');
    expect(tr(ctx, 'Today'), 'Today');
  });
}
