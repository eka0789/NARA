import 'package:flutter_test/flutter_test.dart';
import 'package:nara/features/notes/note_format.dart';

void main() {
  test('checklistProgress counts checked and unchecked items', () {
    final (done, total) = checklistProgress('''
# Agenda
- [x] kickoff
- [ ] budget review
- [X] send invite
random text
- [ ] follow up
''');
    expect(done, 2);
    expect(total, 4);
  });

  test('body without checklists yields 0/0', () {
    final (done, total) = checklistProgress('just a thought');
    expect(done, 0);
    expect(total, 0);
  });

  test('bodyPreview strips headings and markers', () {
    expect(bodyPreview('# Kickoff\n- [x] done thing'), 'Kickoff');
    expect(bodyPreview('- [ ] buy milk'), 'buy milk');
    expect(bodyPreview('plain body'), 'plain body');
  });

  test('bodyPreview truncates long lines with ellipsis', () {
    final preview = bodyPreview('a' * 120, maxLength: 90);
    expect(preview.length, 91); // 90 chars + ellipsis
    expect(preview.endsWith('…'), isTrue);
  });
}
