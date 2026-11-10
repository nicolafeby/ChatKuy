import 'package:chatkuy/core/utils/chat_file_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps supported chat documents to Storage-compatible MIME types', () {
    expect(chatDocumentContentType('report.PDF'), 'application/pdf');
    expect(chatDocumentContentType('letter.doc'), 'application/msword');
    expect(
      chatDocumentContentType('letter.docx'),
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    );
    expect(chatDocumentContentType('sheet.xls'), 'application/vnd.ms-excel');
    expect(
      chatDocumentContentType('sheet.xlsx'),
      'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
    expect(chatDocumentContentType('notes.txt'), 'text/plain');
    expect(chatDocumentContentType('rows.csv'), 'text/csv');
  });

  test('rejects document types not allowed by Storage rules', () {
    expect(chatDocumentContentType('archive.zip'), isNull);
    expect(chatDocumentContentType('no-extension'), isNull);
  });
}
