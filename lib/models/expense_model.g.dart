// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) => ExpenseModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String?,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String?,
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      description: json['description'] as String?,
      vendor: json['vendor'] as String?,
      invoiceNumber: json['invoice_number'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] == null
          ? null
          : DateTime.parse(json['approved_at'] as String),
      status: json['status'] as String? ?? 'pending',
      paymentMethod: json['payment_method'] as String?,
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$ExpenseModelToJson(ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'category': instance.category,
      'subcategory': instance.subcategory,
      'amount': instance.amount,
      'expense_date': instance.expenseDate.toIso8601String(),
      'description': instance.description,
      'vendor': instance.vendor,
      'invoice_number': instance.invoiceNumber,
      'receipt_url': instance.receiptUrl,
      'approved_by': instance.approvedBy,
      'approved_at': instance.approvedAt?.toIso8601String(),
      'status': instance.status,
      'payment_method': instance.paymentMethod,
      'notes': instance.notes,
      'created_by': instance.createdBy,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
