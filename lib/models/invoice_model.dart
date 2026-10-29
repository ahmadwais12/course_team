import 'package:json_annotation/json_annotation.dart';

part 'invoice_model.g.dart';

@JsonSerializable()
class Invoice {
  final String id;
  @JsonKey(name: 'invoice_number')
  final String invoiceNumber;
  @JsonKey(name: 'student_id')
  final String? studentId;
  final double amount;
  @JsonKey(name: 'due_date')
  final DateTime? dueDate;
  final String status; // 'Paid', 'Pending', 'Overdue', 'Cancelled'
  @JsonKey(name: 'issue_date')
  final DateTime? issueDate;
  @JsonKey(name: 'paid_date')
  final DateTime? paidDate;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  @JsonKey(name: 'transaction_id')
  final String? transactionId;
  final String? description;
  final List<Map<String, dynamic>>? items;
  @JsonKey(name: 'discount_amount')
  final double discountAmount;
  @JsonKey(name: 'tax_amount')
  final double taxAmount;
  @JsonKey(name: 'total_amount')
  final double? totalAmount;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Invoice({
    required this.id,
    required this.invoiceNumber,
    this.studentId,
    required this.amount,
    this.dueDate,
    this.status = 'Pending',
    this.issueDate,
    this.paidDate,
    this.paymentMethod,
    this.transactionId,
    this.description,
    this.items,
    this.discountAmount = 0.0,
    this.taxAmount = 0.0,
    this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) => _$InvoiceFromJson(json);
  Map<String, dynamic> toJson() => _$InvoiceToJson(this);

  double get calculatedTotal {
    final subtotal = amount - discountAmount;
    return subtotal + taxAmount;
  }

  bool get isPaid => status == 'Paid';
  bool get isPending => status == 'Pending';
  bool get isOverdue => status == 'Overdue';
  bool get isCancelled => status == 'Cancelled';

  bool get isOverdueCheck {
    if (dueDate == null || isPaid || isCancelled) return false;
    return DateTime.now().isAfter(dueDate!);
  }
}
