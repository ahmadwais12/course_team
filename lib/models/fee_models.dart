// Fee engine models: fee_types, fee_structures, student_fee_assignments,
// fee_installments.  Hand-written fromJson/toJson (no build_runner needed).
//
// Columns mirror supabase_schema.sql. Display fields such as [feeTypeName] /
// [studentName] are populated from joins and are NOT persisted.

const List<String> feeCategories = [
  'tuition', 'admission', 'lab', 'library', 'sports',
  'exam', 'transport', 'hostel', 'activity', 'other',
];

const List<String> feeFrequencies = [
  'monthly', 'quarterly', 'yearly', 'one_time',
];

const List<String> assignmentStatuses = [
  'pending', 'partial', 'paid', 'overdue', 'waived', 'cancelled',
];

class FeeType {
  final String id;
  final String? tenantId;
  final String name;
  final String? nameAr;
  final String? description;
  final String? category;
  final bool isRecurring;
  final String? recurrence;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const FeeType({
    required this.id,
    this.tenantId,
    required this.name,
    this.nameAr,
    this.description,
    this.category,
    this.isRecurring = false,
    this.recurrence,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory FeeType.fromJson(Map<String, dynamic> json) => FeeType(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String?,
        name: (json['name'] as String?) ?? '',
        nameAr: json['name_ar'] as String?,
        description: json['description'] as String?,
        category: json['category'] as String?,
        isRecurring: (json['is_recurring'] as bool?) ?? false,
        recurrence: json['recurrence'] as String?,
        isActive: (json['is_active'] as bool?) ?? true,
        createdAt: _toDate(json['created_at']),
        updatedAt: _toDate(json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        if (tenantId != null) 'tenant_id': tenantId,
        'name': name,
        if (nameAr != null) 'name_ar': nameAr,
        if (description != null) 'description': description,
        if (category != null) 'category': category,
        'is_recurring': isRecurring,
        if (recurrence != null) 'recurrence': recurrence,
        'is_active': isActive,
      };
}

class FeeStructure {
  final String id;
  final String? tenantId;
  final String? feeTypeId;
  final String? programId;
  final String? classId;
  final String name;
  final String? description;
  final double amount;
  final String currency;
  final String? frequency;
  final int? dueDay;
  final double lateFee;
  final String? lateFeeType;
  final double earlyBirdDiscount;
  final DateTime? earlyBirdUntil;
  final double groupDiscount;
  final int groupMinSize;
  final DateTime? effectiveFrom;
  final DateTime? effectiveUntil;
  final bool isActive;
  final String? feeTypeName; // joined display field
  final String? programName; // joined display field
  final String? className; // joined display field

  const FeeStructure({
    required this.id,
    this.tenantId,
    this.feeTypeId,
    this.programId,
    this.classId,
    required this.name,
    this.description,
    required this.amount,
    this.currency = 'AFN',
    this.frequency,
    this.dueDay,
    this.lateFee = 0,
    this.lateFeeType,
    this.earlyBirdDiscount = 0,
    this.earlyBirdUntil,
    this.groupDiscount = 0,
    this.groupMinSize = 0,
    this.effectiveFrom,
    this.effectiveUntil,
    this.isActive = true,
    this.feeTypeName,
    this.programName,
    this.className,
  });

  factory FeeStructure.fromJson(Map<String, dynamic> json) => FeeStructure(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String?,
        feeTypeId: json['fee_type_id'] as String?,
        programId: json['program_id'] as String?,
        classId: json['class_id'] as String?,
        name: (json['name'] as String?) ?? '',
        description: json['description'] as String?,
        amount: _num(json['amount']),
        currency: (json['currency'] as String?) ?? 'AFN',
        frequency: json['frequency'] as String?,
        dueDay: json['due_day'] as int?,
        lateFee: _num(json['late_fee']),
        lateFeeType: json['late_fee_type'] as String?,
        earlyBirdDiscount: _num(json['early_bird_discount']),
        earlyBirdUntil: _toDateOnly(json['early_bird_until']),
        groupDiscount: _num(json['group_discount']),
        groupMinSize: (json['group_min_size'] as num?)?.toInt() ?? 0,
        effectiveFrom: _toDateOnly(json['effective_from']),
        effectiveUntil: _toDateOnly(json['effective_until']),
        isActive: (json['is_active'] as bool?) ?? true,
        feeTypeName: json['fee_type_name'] as String?,
        programName: json['program_name'] as String?,
        className: json['class_name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        if (tenantId != null) 'tenant_id': tenantId,
        if (feeTypeId != null) 'fee_type_id': feeTypeId,
        if (programId != null) 'program_id': programId,
        if (classId != null) 'class_id': classId,
        'name': name,
        if (description != null) 'description': description,
        'amount': amount,
        'currency': currency,
        if (frequency != null) 'frequency': frequency,
        if (dueDay != null) 'due_day': dueDay,
        'late_fee': lateFee,
        if (lateFeeType != null) 'late_fee_type': lateFeeType,
        'early_bird_discount': earlyBirdDiscount,
        if (earlyBirdUntil != null) 'early_bird_until': _dateOnly(earlyBirdUntil!),
        'group_discount': groupDiscount,
        'group_min_size': groupMinSize,
        if (effectiveFrom != null) 'effective_from': _dateOnly(effectiveFrom!),
        if (effectiveUntil != null) 'effective_until': _dateOnly(effectiveUntil!),
        'is_active': isActive,
      };
}

class StudentFeeAssignment {
  final String id;
  final String? tenantId;
  final String? studentId;
  final String? studentName; // joined display field
  final String? feeStructureId;
  final String? feeTypeId;
  final String? feeTypeName; // joined display field
  final String? structureName; // joined display field
  final double amount;
  final String? currency;
  final DateTime dueDate;
  final String? frequency;
  final String status;
  final double paidAmount;
  final double lateFeeApplied;
  final double discountAmount;
  final String? discountReason;
  final String? notes;
  final String? waivedBy;
  final DateTime? waivedAt;
  final String? waiverReason;
  final String? assignedBy;
  final DateTime? assignedAt;

  const StudentFeeAssignment({
    required this.id,
    this.tenantId,
    this.studentId,
    this.studentName,
    this.feeStructureId,
    this.feeTypeId,
    this.feeTypeName,
    this.structureName,
    required this.amount,
    this.currency = 'AFN',
    required this.dueDate,
    this.frequency,
    this.status = 'pending',
    this.paidAmount = 0,
    this.lateFeeApplied = 0,
    this.discountAmount = 0,
    this.discountReason,
    this.notes,
    this.waivedBy,
    this.waivedAt,
    this.waiverReason,
    this.assignedBy,
    this.assignedAt,
  });

  double get outstandingAmount => (amount - paidAmount).clamp(0, double.infinity).toDouble();

  factory StudentFeeAssignment.fromJson(Map<String, dynamic> json) =>
      StudentFeeAssignment(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String?,
        studentId: json['student_id'] as String?,
        studentName: json['student_name'] as String?,
        feeStructureId: json['fee_structure_id'] as String?,
        feeTypeId: json['fee_type_id'] as String?,
        feeTypeName: json['fee_type_name'] as String?,
        structureName: json['structure_name'] as String?,
        amount: _num(json['amount']),
        currency: (json['currency'] as String?) ?? 'AFN',
        dueDate: _toDate(json['due_date']) ?? DateTime.now(),
        frequency: json['frequency'] as String?,
        status: (json['status'] as String?) ?? 'pending',
        paidAmount: _num(json['paid_amount']),
        lateFeeApplied: _num(json['late_fee_applied']),
        discountAmount: _num(json['discount_amount']),
        discountReason: json['discount_reason'] as String?,
        notes: json['notes'] as String?,
        waivedBy: json['waived_by'] as String?,
        waivedAt: _toDate(json['waived_at']),
        waiverReason: json['waiver_reason'] as String?,
        assignedBy: json['assigned_by'] as String?,
        assignedAt: _toDate(json['assigned_at']),
      );

  Map<String, dynamic> toInsertJson() => {
        if (tenantId != null) 'tenant_id': tenantId,
        if (studentId != null) 'student_id': studentId,
        if (feeStructureId != null) 'fee_structure_id': feeStructureId,
        if (feeTypeId != null) 'fee_type_id': feeTypeId,
        'amount': amount,
        if (currency != null) 'currency': currency,
        'due_date': _dateOnly(dueDate),
        if (frequency != null) 'frequency': frequency,
        'status': status,
        if (discountAmount > 0) 'discount_amount': discountAmount,
        if (discountReason != null && discountReason!.isNotEmpty)
          'discount_reason': discountReason,
        if (notes != null && notes!.isNotEmpty) 'notes': notes,
        if (assignedBy != null) 'assigned_by': assignedBy,
      };
}

class FeeInstallment {
  final String id;
  final String? tenantId;
  final String? studentId;
  final String? feeAssignmentId;
  final int installmentNumber;
  final int totalInstallments;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final double paidAmount;
  final String status;
  final String? paymentId;
  final double lateFee;

  const FeeInstallment({
    required this.id,
    this.tenantId,
    this.studentId,
    this.feeAssignmentId,
    required this.installmentNumber,
    required this.totalInstallments,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.paidAmount = 0,
    this.status = 'pending',
    this.paymentId,
    this.lateFee = 0,
  });

  factory FeeInstallment.fromJson(Map<String, dynamic> json) =>
      FeeInstallment(
        id: json['id'] as String,
        tenantId: json['tenant_id'] as String?,
        studentId: json['student_id'] as String?,
        feeAssignmentId: json['fee_assignment_id'] as String?,
        installmentNumber: (json['installment_number'] as num?)?.toInt() ?? 1,
        totalInstallments: (json['total_installments'] as num?)?.toInt() ?? 1,
        amount: _num(json['amount']),
        dueDate: _toDate(json['due_date']) ?? DateTime.now(),
        paidDate: _toDate(json['paid_date']),
        paidAmount: _num(json['paid_amount']),
        status: (json['status'] as String?) ?? 'pending',
        paymentId: json['payment_id'] as String?,
        lateFee: _num(json['late_fee']),
      );

  double get outstandingAmount => (amount - paidAmount).clamp(0, double.infinity).toDouble();

  Map<String, dynamic> toInsertJson() => {
        if (tenantId != null) 'tenant_id': tenantId,
        if (studentId != null) 'student_id': studentId,
        if (feeAssignmentId != null) 'fee_assignment_id': feeAssignmentId,
        'installment_number': installmentNumber,
        'total_installments': totalInstallments,
        'amount': amount,
        'due_date': _dateOnly(dueDate),
        'status': status,
        'late_fee': lateFee,
      };
}

// ────────────────────────────────────────────────────────────────────────────
// Shared helpers
// ────────────────────────────────────────────────────────────────────────────

double _num(dynamic v) =>
    v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '') ?? 0;

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}

DateTime? _toDateOnly(dynamic v) => _toDate(v);

String _dateOnly(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
