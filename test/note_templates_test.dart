import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:nara/features/notes/note_templates.dart';
import 'package:nara/l10n/generated/app_localizations.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  test('offers blank + three structured templates, localized', () {
    final l10n = lookupAppLocalizations(const Locale('en'));
    final templates = noteTemplates(l10n, DateTime(2026, 11, 15));

    expect(templates.map((t) => t.id), ['blank', 'journal', 'meeting', 'project']);
    expect(templates.first.body, isEmpty);

    final journal = templates[1];
    expect(journal.title, contains('Nov 15'));
    expect(journal.body, contains('- [ ]'));
    expect(templates[2].body, contains('- [ ]'));
    expect(templates[3].body, contains('- [ ]'));
  });

  test('Indonesian locale produces Indonesian template content', () {
    final l10n = lookupAppLocalizations(const Locale('id'));
    final templates = noteTemplates(l10n, DateTime(2026, 11, 15));

    expect(templates[1].title, contains('Jurnal harian'));
    expect(templates[1].body, contains('prioritas'));
  });
}
