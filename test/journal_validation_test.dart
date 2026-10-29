import 'package:flutter_test/flutter_test.dart';
import 'package:course_emis/services/journal_service.dart';

void main() {
  group('JournalValidator.validate', () {
    test('balanced journal passes', () {
      final result = JournalValidator.validate([
        JournalLine.debit('1001', 1000),
        JournalLine.credit('4001', 1000),
      ]);
      expect(result.error, isNull);
      expect(result.totalDebit, 1000);
      expect(result.totalCredit, 1000);
    });

    test('multi-line balanced journal passes', () {
      final result = JournalValidator.validate([
        JournalLine.debit('1001', 500),
        JournalLine.debit('1001', 500),
        JournalLine.credit('4001', 1000),
      ]);
      expect(result.error, isNull);
      expect(result.totalDebit, 1000);
    });

    test('unbalanced journal is rejected', () {
      final result = JournalValidator.validate([
        JournalLine.debit('1001', 900),
        JournalLine.credit('4001', 1000),
      ]);
      expect(result.error, isNotNull);
      expect(result.error, contains('not balanced'));
    });

    test('empty journal is rejected', () {
      final result = JournalValidator.validate([]);
      expect(result.error, isNotNull);
    });

    test('a line cannot be both debit and credit', () {
      final result = JournalValidator.validate([
        const JournalLine(accountCode: '1001', debit: 100, credit: 100),
      ]);
      expect(result.error, isNotNull);
    });

    test('negative amounts are rejected', () {
      final result = JournalValidator.validate([
        JournalLine.debit('1001', -5),
      ]);
      expect(result.error, isNotNull);
    });

    test('zero-amount line is rejected', () {
      final result = JournalValidator.validate([
        const JournalLine(accountCode: '1001'),
      ]);
      expect(result.error, isNotNull);
    });

    test('rounding-safe: two halves of an odd amount still balance', () {
      final result = JournalValidator.validate([
        JournalLine.debit('1001', 333.335),
        JournalLine.credit('4001', 333.335),
      ]);
      expect(result.error, isNull);
      expect(result.totalDebit, result.totalCredit);
      expect(result.totalDebit, greaterThan(0));
    });
  });
}
