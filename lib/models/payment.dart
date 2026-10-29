enum PaymentMethod {
  cash,
  installment,
  card,
  // Wire values are snake_case and are persisted/serialized via `.name`,
  // so they must stay identical to the database values.
  // ignore: constant_identifier_names
  bank_transfer,
  online,
  check,
  // ignore: constant_identifier_names
  mobile_payment,
}
enum PaymentStatus { pending, paid, overdue, completed, failed, refunded, voided }

class Payment {
  final String id;
  final String studentId;
  final double amount;
  final PaymentMethod method;
  final PaymentStatus status;
  final DateTime? dueDate;
  final DateTime? paidDate;
  final String? receiptUrl;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.method,
    required this.status,
    this.dueDate,
    this.paidDate,
    this.receiptUrl,
    required this.createdAt,
  });

  static T _enumByName<T extends Enum>(List<T> values, dynamic raw, T fallback) {
    final name = raw?.toString();
    if (name == null) return fallback;
    return values.firstWhere(
      (e) => e.name == name,
      orElse: () => fallback,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'amount': amount,
        'payment_method': method.name,
        'status': status.name,
        'due_date': dueDate?.toIso8601String(),
        'paid_date': paidDate?.toIso8601String(),
        'receipt_url': receiptUrl,
        'created_at': createdAt.toIso8601String(),
      };

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'] as String,
        studentId: (json['student_id'] ?? json['studentId']) as String,
        amount: (json['amount'] as num).toDouble(),
        method: _enumByName(
          PaymentMethod.values,
          json['payment_method'] ?? json['method'],
          PaymentMethod.cash,
        ),
        status: _enumByName(
          PaymentStatus.values,
          json['status'],
          PaymentStatus.pending,
        ),
        dueDate: (json['due_date'] ?? json['dueDate']) != null
            ? DateTime.parse((json['due_date'] ?? json['dueDate']).toString())
            : null,
        paidDate: (json['paid_date'] ?? json['paidDate'] ?? json['payment_date']) != null
            ? DateTime.parse(
                (json['paid_date'] ?? json['paidDate'] ?? json['payment_date'])
                    .toString())
            : null,
        receiptUrl: (json['receipt_url'] ?? json['receiptUrl']) as String?,
        createdAt: DateTime.parse(
            (json['created_at'] ?? json['createdAt']).toString()),
      );

  Payment copyWith({
    String? id,
    String? studentId,
    double? amount,
    PaymentMethod? method,
    PaymentStatus? status,
    DateTime? dueDate,
    DateTime? paidDate,
    String? receiptUrl,
    DateTime? createdAt,
  }) =>
      Payment(
        id: id ?? this.id,
        studentId: studentId ?? this.studentId,
        amount: amount ?? this.amount,
        method: method ?? this.method,
        status: status ?? this.status,
        dueDate: dueDate ?? this.dueDate,
        paidDate: paidDate ?? this.paidDate,
        receiptUrl: receiptUrl ?? this.receiptUrl,
        createdAt: createdAt ?? this.createdAt,
      );
}
