/// Lightweight markdown-ish parsing for note bodies: GitHub-style
/// checklists (`- [ ]` / `- [x]`) surface as a progress chip on note cards
/// and in Quick Find, without needing a block editor.
library;

/// Returns (done, total) checklist items found in [body].
(int done, int total) checklistProgress(String body) {
  var done = 0;
  var total = 0;
  for (final line in body.split('\n')) {
    final trimmed = line.trimLeft();
    final checked = trimmed.startsWith('- [x]') || trimmed.startsWith('- [X]');
    final unchecked = trimmed.startsWith('- [ ]');
    if (checked) {
      done++;
      total++;
    } else if (unchecked) {
      total++;
    }
  }
  return (done, total);
}

/// The note body with the first heading line or checklist markers stripped —
/// a readable one-line preview for cards and search results.
String bodyPreview(String body, {int maxLength = 90}) {
  var text = body.trim();
  for (final line in text.split('\n')) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    text = trimmed
        .replaceFirst(RegExp(r'^#+\s*'), '')
        .replaceFirst(RegExp(r'^- \[[xX ]\]\s*'), '')
        .replaceFirst(RegExp(r'^[-*]\s*'), '');
    break;
  }
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength)}…';
}
