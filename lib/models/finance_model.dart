import 'package:json_annotation/json_annotation.dart';

part 'finance_model.g.dart';

@JsonSerializable()
class Transaction {
  final String id;
  final String type;
  final double amount;
  final String description;
  final DateTime date;
  final String category;
  @JsonKey(name: 'student_id')
  final String? studentId;
  @JsonKey(name: 'staff_id')
  final String? staffId;
  final String status;
  final String? notes;

  Transaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    this.studentId,
    this.staffId,
    required this.status,
    this.notes,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);
  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}

@JsonSerializable()
class Fee {
  final String id;
  @JsonKey(name: 'student_id')
  final String studentId;
  final double amount;
  @JsonKey(name: 'fee_type')
  final String feeType;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  final String status;
  @JsonKey(name: 'paid_date')
  final DateTime? paidDate;

  Fee({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.feeType,
    required this.dueDate,
    required this.status,
    this.paidDate,
  });

  factory Fee.fromJson(Map<String, dynamic> json) => _$FeeFromJson(json);
  Map<String, dynamic> toJson() => _$FeeToJson(this);
}

@JsonSerializable()
class Finance {
  final List<Transaction> transactions;
  final List<Fee> fees;
  final double totalIncome;
  final double totalExpense;
  final double balance;

  Finance({
    required this.transactions,
    required this.fees,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
  });

  factory Finance.fromJson(Map<String, dynamic> json) => _$FinanceFromJson(json);
  Map<String, dynamic> toJson() => _$FinanceToJson(this);
}
