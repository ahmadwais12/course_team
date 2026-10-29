// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'finance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      id: json['id'] as String,
      type: json['type'] as String,
      amount: (json['amount'] as num).toDouble(),
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      studentId: json['student_id'] as String?,
      staffId: json['staff_id'] as String?,
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'amount': instance.amount,
      'description': instance.description,
      'date': instance.date.toIso8601String(),
      'category': instance.category,
      'student_id': instance.studentId,
      'staff_id': instance.staffId,
      'status': instance.status,
      'notes': instance.notes,
    };

Fee _$FeeFromJson(Map<String, dynamic> json) => Fee(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      feeType: json['fee_type'] as String,
      dueDate: DateTime.parse(json['due_date'] as String),
      status: json['status'] as String,
      paidDate: json['paid_date'] == null
          ? null
          : DateTime.parse(json['paid_date'] as String),
    );

Map<String, dynamic> _$FeeToJson(Fee instance) => <String, dynamic>{
      'id': instance.id,
      'student_id': instance.studentId,
      'amount': instance.amount,
      'fee_type': instance.feeType,
      'due_date': instance.dueDate.toIso8601String(),
      'status': instance.status,
      'paid_date': instance.paidDate?.toIso8601String(),
    };

Finance _$FinanceFromJson(Map<String, dynamic> json) => Finance(
      transactions: (json['transactions'] as List<dynamic>)
          .map((e) => Transaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      fees: (json['fees'] as List<dynamic>)
          .map((e) => Fee.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalIncome: (json['totalIncome'] as num).toDouble(),
      totalExpense: (json['totalExpense'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
    );

Map<String, dynamic> _$FinanceToJson(Finance instance) => <String, dynamic>{
      'transactions': instance.transactions,
      'fees': instance.fees,
      'totalIncome': instance.totalIncome,
      'totalExpense': instance.totalExpense,
      'balance': instance.balance,
    };
