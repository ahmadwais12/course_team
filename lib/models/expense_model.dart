import 'package:json_annotation/json_annotation.dart';

part 'expense_model.g.dart';

@JsonSerializable()
class ExpenseModel {
  final String id;
  @JsonKey(name: 'tenant_id')
  final String? tenantId;
  final String category;
  final String? subcategory;
  final double amount;
  @JsonKey(name: 'expense_date')
  final DateTime expenseDate;
  final String? description;
  final String? vendor;
  @JsonKey(name: 'invoice_number')
  final String? invoiceNumber;
  @JsonKey(name: 'receipt_url')
  final String? receiptUrl;
  @JsonKey(name: 'approved_by')
  final String? approvedBy;
  @JsonKey(name: 'approved_at')
  final DateTime? approvedAt;
  final String status;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  final String? notes;
  @JsonKey(name: 'created_by')
  final String? createdBy;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    this.tenantId,
    required this.category,
    this.subcategory,
    required this.amount,
    required this.expenseDate,
    this.description,
    this.vendor,
    this.invoiceNumber,
    this.receiptUrl,
    this.approvedBy,
    this.approvedAt,
    this.status = 'pending',
    this.paymentMethod,
    this.notes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);
}
