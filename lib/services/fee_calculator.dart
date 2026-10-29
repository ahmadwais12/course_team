library;

import 'package:course_emis/models/fee_models.dart';

/// Pure calculation helpers for the fee engine (no DB access, unit-testable).
///
/// Follows the Finance module guide §6.2 — a discount/promotion can be a
/// percentage of the base amount or a fixed amount, capped by an optional
/// maximum discount and only valid above an optional minimum purchase.

class DiscountInput {
  final double? percentage; // e.g. 10.0 == 10%
  final double? fixedAmount; // absolute AFN/PKR off the total
  final double? maxAmount; // ceiling for the computed discount
  final double? minPurchaseAmount; // discount only applies above this subtotal

  const DiscountInput({
    this.percentage,
    this.fixedAmount,
    this.maxAmount,
    this.minPurchaseAmount,
  });

  bool get hasDiscount =>
      (percentage != null && percentage! > 0) ||
      (fixedAmount != null && fixedAmount! > 0);
}

/// Rounds to 2 decimals the way DECIMAL(12,2) columns store money.
double money2(double v) => double.parse(v.toStringAsFixed(2));

/// Computes the final payable amount for [baseAmount] after applying the
/// optional [discount] to [quantity] units.
double calculateFinalAmount({
  required double baseAmount,
  DiscountInput? discount,
  int quantity = 1,
}) {
  if (quantity < 1) quantity = 1;
  final subtotal = baseAmount * quantity;

  final d = discount;
  if (d == null || !d.hasDiscount) return money2(subtotal);

  if (d.minPurchaseAmount != null && subtotal < d.minPurchaseAmount!) {
    return money2(subtotal);
  }

  double discountValue = 0;
  if (d.fixedAmount != null && d.fixedAmount! > 0) {
    discountValue = d.fixedAmount!;
  } else if (d.percentage != null && d.percentage! > 0) {
    discountValue = subtotal * d.percentage! / 100;
  }
  if (d.maxAmount != null && discountValue > d.maxAmount!) {
    discountValue = d.maxAmount!;
  }

  return money2((subtotal - discountValue).clamp(0, double.infinity));
}

/// Late-fee rules on a [FeeStructure]: fixed amount or percentage of amount.
double calculateLateFee({
  required FeeStructure structure,
  required DateTime dueDate,
  DateTime? onDate,
  int graceDays = 0,
}) {
  final asOf = onDate ?? DateTime.now();
  if (structure.lateFee <= 0) return 0;
  if (!asOf.isAfter(dueDate.add(Duration(days: graceDays)))) return 0;

  if (structure.lateFeeType == 'percentage') {
    return money2(structure.amount * structure.lateFee / 100);
  }
  return money2(structure.lateFee); // fixed
}

/// Chart-of-accounts income account code for a fee category (seeded codes).
String incomeAccountCodeForCategory(String? category) {
  switch (category) {
    case 'tuition':
      return '4001';
    case 'admission':
      return '4002';
    case 'lab':
      return '4003';
    case 'library':
      return '4004';
    case 'transport':
      return '4005';
    case 'hostel':
      return '4006';
    default:
      return '4007'; // Other Income (sports, exam, activity, other)
  }
}

/// Cash asset account code used on the debit side of a fee payment.
/// The seeded chart has Cash on Hand (1001) + Petty Cash Fund (1002);
/// non-cash methods map to the same cash control account for now.
String cashAccountCodeForMethod(String? paymentMethod) {
  switch ((paymentMethod ?? '').toLowerCase()) {
    case 'cash':
    case '':
      return '1001';
    default:
      return '1001';
  }
}

/// Splits [total] into [parts] equal installments (last one absorbs rounding).
List<double> splitInstallments(double total, int parts) {
  if (parts <= 1) return [money2(total)];
  final base = money2(total / parts);
  final result = List<double>.filled(parts, base);
  final sum = money2(base * parts);
  result[parts - 1] = money2(result[parts - 1] + (total - sum));
  return result;
}

/// Builds installment due dates starting at [startDate], advancing one
/// [frequency] interval per installment.
List<DateTime> installmentDueDates({
  required DateTime startDate,
  required int parts,
  required String? frequency,
}) {
  final dates = <DateTime>[];
  for (var i = 0; i < parts; i++) {
    DateTime d = startDate;
    if (i > 0) {
      switch (frequency) {
        case 'monthly':
          d = _addMonthsClamped(startDate, i);
        case 'quarterly':
          d = _addMonthsClamped(startDate, i * 3);
        case 'yearly':
          d = DateTime(startDate.year + i, startDate.month,
              _clampDay(startDate.year + i, startDate.month, startDate.day));
        default:
          // one_time / no frequency: fall back to monthly spacing
          d = _addMonthsClamped(startDate, i);
      }
    }
    dates.add(d);
  }
  return dates;
}

/// Adds [months] without rolling short months over (31 Jan + 1 month = 28 Feb).
DateTime _addMonthsClamped(DateTime d, int months) {
  final total = d.year * 12 + (d.month - 1) + months;
  final y = total ~/ 12;
  final m = total % 12 + 1;
  final lastDay = DateTime(y, m + 1, 0).day;
  return DateTime(y, m, d.day > lastDay ? lastDay : d.day);
}

int _clampDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return day > lastDay ? lastDay : day;
}

/// Map a fee category to a human label for dropdowns.
String categoryLabel(String category) {
  const labels = {
    'tuition': 'Tuition',
    'admission': 'Admission',
    'lab': 'Lab',
    'library': 'Library',
    'sports': 'Sports',
    'exam': 'Exam',
    'transport': 'Transport',
    'hostel': 'Hostel',
    'activity': 'Activity',
    'other': 'Other',
  };
  return labels[category] ?? category;
}

/// Map a frequency / recurrence value to a human label.
String frequencyLabel(String? frequency) {
  switch (frequency) {
    case 'monthly':
      return 'Monthly';
    case 'quarterly':
      return 'Quarterly';
    case 'yearly':
      return 'Yearly';
    case 'one_time':
      return 'One Time';
    default:
      return 'One Time';
  }
}
