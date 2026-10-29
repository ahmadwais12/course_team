import 'package:flutter_test/flutter_test.dart';
import 'package:course_emis/services/fee_calculator.dart';

void main() {
  group('calculateFinalAmount', () {
    test('no discount returns the base amount', () {
      expect(calculateFinalAmount(baseAmount: 5000), 5000.0);
    });

    test('percentage discount', () {
      final result = calculateFinalAmount(
        baseAmount: 5000,
        discount: const DiscountInput(percentage: 10),
      );
      expect(result, 4500.0);
    });

    test('fixed discount', () {
      final result = calculateFinalAmount(
        baseAmount: 5000,
        discount: const DiscountInput(fixedAmount: 200),
      );
      expect(result, 4800.0);
    });

    test('fixed discount wins over percentage when both provided', () {
      final result = calculateFinalAmount(
        baseAmount: 10000,
        discount: const DiscountInput(percentage: 25, fixedAmount: 500),
      );
      expect(result, 9500.0);
    });

    test('max amount caps the discount', () {
      final result = calculateFinalAmount(
        baseAmount: 10000,
        discount: const DiscountInput(percentage: 25, maxAmount: 1000),
      );
      expect(result, 9000.0);
    });

    test('min purchase below threshold disables the discount', () {
      final result = calculateFinalAmount(
        baseAmount: 500,
        discount: const DiscountInput(percentage: 10, minPurchaseAmount: 1000),
      );
      expect(result, 500.0);
    });

    test('quantity multiplies the base', () {
      final result = calculateFinalAmount(
        baseAmount: 250,
        discount: const DiscountInput(percentage: 20),
        quantity: 4,
      );
      expect(result, 800.0);
    });

    test('discount never makes the total negative', () {
      final result = calculateFinalAmount(
        baseAmount: 100,
        discount: const DiscountInput(fixedAmount: 500),
      );
      expect(result, 0.0);
    });
  });

  group('splitInstallments', () {
    test('splits evenly and keeps rounding on the last part', () {
      final parts = splitInstallments(100.01, 3);
      expect(parts.length, 3);
      final sum = parts.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(100.01, 0.0001));
    });

    test('single part returns the whole amount', () {
      expect(splitInstallments(2500, 1), [2500.0]);
    });
  });

  group('installmentDueDates', () {
    test('monthly spacing advances months', () {
      final dates = installmentDueDates(
        startDate: DateTime(2026, 1, 31),
        parts: 3,
        frequency: 'monthly',
      );
      expect(dates[0].month, 1);
      expect(dates[1].month, 2);
      expect(dates[2].month, 3);
    });

    test('one_time frequency falls back to monthly spacing', () {
      final dates = installmentDueDates(
        startDate: DateTime(2026, 6, 15),
        parts: 2,
        frequency: 'one_time',
      );
      expect(dates.length, 2);
      expect(dates[0].month, 6);
      expect(dates[1].month, 7);
    });
  });

  group('account mapping', () {
    test('income accounts by fee category', () {
      expect(incomeAccountCodeForCategory('tuition'), '4001');
      expect(incomeAccountCodeForCategory('admission'), '4002');
      expect(incomeAccountCodeForCategory('lab'), '4003');
      expect(incomeAccountCodeForCategory('library'), '4004');
      expect(incomeAccountCodeForCategory('transport'), '4005');
      expect(incomeAccountCodeForCategory('hostel'), '4006');
      expect(incomeAccountCodeForCategory('sports'), '4007');
      expect(incomeAccountCodeForCategory('exam'), '4007');
      expect(incomeAccountCodeForCategory(null), '4007');
    });

    test('cash account always maps to cash on hand (1001)', () {
      expect(cashAccountCodeForMethod('cash'), '1001');
      expect(cashAccountCodeForMethod('bank_transfer'), '1001');
      expect(cashAccountCodeForMethod(null), '1001');
    });
  });
}

