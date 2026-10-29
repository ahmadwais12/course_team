// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invoice_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Invoice _$InvoiceFromJson(Map<String, dynamic> json) => Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoice_number'] as String,
      studentId: json['student_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      status: json['status'] as String? ?? 'Pending',
      issueDate: json['issue_date'] == null
          ? null
          : DateTime.parse(json['issue_date'] as String),
      paidDate: json['paid_date'] == null
          ? null
          : DateTime.parse(json['paid_date'] as String),
      paymentMethod: json['payment_method'] as String?,
      transactionId: json['transaction_id'] as String?,
      description: json['description'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => e as Map<String, dynamic>)
          .toList(),
      discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['total_amount'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$InvoiceToJson(Invoice instance) => <String, dynamic>{
      'id': instance.id,
      'invoice_number': instance.invoiceNumber,
      'student_id': instance.studentId,
      'amount': instance.amount,
      'due_date': instance.dueDate?.toIso8601String(),
      'status': instance.status,
      'issue_date': instance.issueDate?.toIso8601String(),
      'paid_date': instance.paidDate?.toIso8601String(),
      'payment_method': instance.paymentMethod,
      'transaction_id': instance.transactionId,
      'description': instance.description,
      'items': instance.items,
      'discount_amount': instance.discountAmount,
      'tax_amount': instance.taxAmount,
      'total_amount': instance.totalAmount,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
