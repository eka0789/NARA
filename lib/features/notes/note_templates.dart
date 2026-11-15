import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../l10n/generated/app_localizations.dart';

/// A starting point for a new page — Notion's "New page" menu. Bodies use
/// GitHub-style markdown: `##` headings and `- [ ]` checklists, which the
/// note cards render as live progress chips.
class NoteTemplate {
  const NoteTemplate({required this.id, required this.title, required this.body});

  final String id;
  final String title;
  final String body;
}

/// The template menu, localized, with today's date baked into the journal
/// title (the daily-journal ritual is the point of a template).
List<NoteTemplate> noteTemplates(AppLocalizations l10n, DateTime now) {
  // intl requires date symbols before any DateFormat use; the embedded
  // dataset covers every locale and repeats are cheap. (The synchronous
  // initialization happens before the returned future completes, so using
  // DateFormat right after this call is safe.)
  unawaited(initializeDateFormatting());
  final date = DateFormat.MMMEd(l10n.localeName).format(now);
  return [
    NoteTemplate(id: 'blank', title: l10n.templateBlank, body: ''),
    NoteTemplate(
      id: 'journal',
      title: '${l10n.tplJournalTitle} — $date',
      body: l10n.tplJournalBody,
    ),
    NoteTemplate(
      id: 'meeting',
      title: l10n.tplMeetingTitle,
      body: l10n.tplMeetingBody,
    ),
    NoteTemplate(
      id: 'project',
      title: l10n.tplProjectTitle,
      body: l10n.tplProjectBody,
    ),
  ];
}
