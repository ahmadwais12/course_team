import 'package:flutter/foundation.dart';
import 'package:course_emis/models/fee_models.dart';
import 'package:course_emis/services/fee_calculator.dart';
import 'package:course_emis/services/journal_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result of recording a fee payment.
class PaymentResult {
  final String paymentId;
  final String? journalId;
  final String? receiptId;
  final String invoiceNumber;
  final double paidSoFar;

  const PaymentResult({
    required this.paymentId,
    this.journalId,
    this.receiptId,
    this.invoiceNumber = '',
    required this.paidSoFar,
  });
}

class _Scope {
  final String? tenantId;
  final String? role;
  final String userId;
  const _Scope({this.tenantId, this.role, required this.userId});
}

/// Data access + business workflow for the student fee engine:
/// fee_types, fee_structures, student_fee_assignments, fee_installments,
/// invoices and payments (double-entry via [JournalService]).
class FeeRepository {
  final SupabaseClient _client;
  final JournalService _journal;

  FeeRepository({SupabaseClient? client, JournalService? journal})
      : _client = client ?? Supabase.instance.client,
        _journal = journal ?? JournalService(client ?? Supabase.instance.client);

  // --------------------------------------------------------------------------
  // Tenant / user scope
  // --------------------------------------------------------------------------

  Future<_Scope> _scope() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      return const _Scope(userId: '');
    }
    String? tenantId;
    String? role;
    try {
      final rows = await _client
          .from('users')
          .select('tenant_id, role')
          .eq('id', uid)
          .limit(1);
      if (rows.isNotEmpty) {
        tenantId = rows.first['tenant_id'] as String?;
        role = rows.first['role'] as String?;
      }
    } catch (_) {
      // Non-fatal: RLS may hide the profile from the anon key path.
    }
    return _Scope(tenantId: tenantId, role: role, userId: uid);
  }

  // --------------------------------------------------------------------------
  // Fee Types CRUD
  // --------------------------------------------------------------------------

  Future<List<FeeType>> listFeeTypes() async {
    final rows = await _client
        .from('fee_types')
        .select()
        .order('name');
    return rows.map((r) => FeeType.fromJson(Map<String, dynamic>.from(r))).toList();
  }

  Future<FeeType> createFeeType({
    required String name,
    String? description,
    String? category,
    bool isRecurring = false,
    String? recurrence,
    bool isActive = true,
  }) async {
    final scope = await _scope();
    final rows = await _client
        .from('fee_types')
        .insert({
          if (scope.tenantId != null) 'tenant_id': scope.tenantId,
          'name': name,
          if (description != null && description.isNotEmpty)
            'description': description,
          if (category != null) 'category': category,
          'is_recurring': isRecurring,
          if (recurrence != null) 'recurrence': recurrence,
          'is_active': isActive,
        })
        .select();
    return FeeType.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<void> updateFeeType(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    await _client.from('fee_types').update(payload).eq('id', id);
  }

  Future<void> deleteFeeType(String id) async {
    await _client.from('fee_types').delete().eq('id', id);
  }

  // --------------------------------------------------------------------------
  // Fee Structures CRUD
  // --------------------------------------------------------------------------

  Future<List<FeeStructure>> listFeeStructures({bool onlyActive = false}) async {
    final rows = await _client
        .from('fee_structures')
        .select()
        .order('name');
    final feeTypes = await _fetchFeeTypeMap();
    final programs = await _fetchNameMap('programs');
    final classes = await _fetchNameMap('classes');

    return rows.map((r) {
      final json = Map<String, dynamic>.from(r);
      json['fee_type_name'] = feeTypes[json['fee_type_id']];
      json['program_name'] = programs[json['program_id']];
      json['class_name'] = classes[json['class_id']];
      final s = FeeStructure.fromJson(json);
      return (onlyActive && !s.isActive) ? null : s;
    }).whereType<FeeStructure>().toList();
  }

  Future<FeeStructure> createFeeStructure({
    required String name,
    required String? feeTypeId,
    String? programId,
    String? classId,
    required double amount,
    String? description,
    String? frequency,
    int? dueDay,
    double lateFee = 0,
    String? lateFeeType,
    double earlyBirdDiscount = 0,
    double groupDiscount = 0,
    bool isActive = true,
  }) async {
    final scope = await _scope();
    final rows = await _client
        .from('fee_structures')
        .insert({
          if (scope.tenantId != null) 'tenant_id': scope.tenantId,
          if (feeTypeId != null) 'fee_type_id': feeTypeId,
          if (programId != null) 'program_id': programId,
          if (classId != null) 'class_id': classId,
          'name': name,
          'amount': amount,
          'currency': 'AFN',
          if (description != null && description.isNotEmpty)
            'description': description,
          if (frequency != null) 'frequency': frequency,
          if (dueDay != null) 'due_day': dueDay,
          'late_fee': lateFee,
          if (lateFeeType != null) 'late_fee_type': lateFeeType,
          'early_bird_discount': earlyBirdDiscount,
          'group_discount': groupDiscount,
          'is_active': isActive,
        })
        .select();
    return FeeStructure.fromJson(Map<String, dynamic>.from(rows.first));
  }

  Future<void> updateFeeStructure(String id, Map<String, dynamic> data) async {
    final payload = Map<String, dynamic>.from(data)
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    await _client.from('fee_structures').update(payload).eq('id', id);
  }

  Future<void> deleteFeeStructure(String id) async {
    await _client.from('fee_structures').delete().eq('id', id);
  }

  // --------------------------------------------------------------------------
  // Assignment + installments
  // --------------------------------------------------------------------------

  Future<List<StudentFeeAssignment>> listAssignments({String? studentId}) async {
    var q = _client.from('student_fee_assignments').select();
    if (studentId != null && studentId.isNotEmpty) {
      q = q.eq('student_id', studentId);
    }
    final rows = await q.order('due_date', ascending: false);
    final feeTypes = await _fetchFeeTypeMap();
    final structures = await _fetchFeeStructureMap();
    final students = await _fetchStudentMap();

    return rows.map((r) {
      final json = Map<String, dynamic>.from(r);
      json['fee_type_name'] = feeTypes[json['fee_type_id']];
      json['structure_name'] = structures[json['fee_structure_id']];
      json['student_name'] = students[json['student_id']];
      return StudentFeeAssignment.fromJson(json);
    }).toList();
  }

  Future<List<FeeInstallment>> listInstallments({String? assignmentId}) async {
    var q = _client.from('fee_installments').select();
    if (assignmentId != null && assignmentId.isNotEmpty) {
      q = q.eq('fee_assignment_id', assignmentId);
    }
    final rows = await q.order('installment_number');
    return rows
        .map((r) => FeeInstallment.fromJson(Map<String, dynamic>.from(r)))
        .toList();
  }

  /// Assigns one or more [structures] to a student. An optional global
  /// percentage [discountPercent] (with reason) is applied to every amount.
  /// When [installmentCount] > 1 the net amount is split into equal
  /// installments spread by the structure frequency.
  Future<List<StudentFeeAssignment>> assignFees({
    required String studentId,
    required List<FeeStructure> structures,
    required DateTime dueDate,
    double discountPercent = 0,
    String? discountReason,
    int? installmentCount,
    String? notes,
  }) async {
    if (structures.isEmpty) {
      throw ArgumentError('Select at least one fee structure.');
    }
    final scope = await _scope();
    final now = DateTime.now();

    final rows = await _client
        .from('student_fee_assignments')
        .insert([
          for (final s in structures)
            {
              if (scope.tenantId != null) 'tenant_id': scope.tenantId,
              'student_id': studentId,
              'fee_structure_id': s.id,
              'fee_type_id': s.feeTypeId,
              'amount': money2(
                discountPercent > 0
                    ? s.amount * (1 - discountPercent / 100)
                    : s.amount,
              ),
              'currency': s.currency,
              'due_date': _dateOnly(dueDate),
              if (s.frequency != null) 'frequency': s.frequency,
              'status': 'pending',
              if (discountPercent > 0) 'discount_amount': money2(s.amount * discountPercent / 100),
              if (discountReason != null && discountReason.isNotEmpty)
                'discount_reason': discountReason,
              if (notes != null && notes.isNotEmpty) 'notes': notes,
              if (scope.userId.isNotEmpty) 'assigned_by': scope.userId,
              'assigned_at': now.toUtc().toIso8601String(),
            },
        ])
        .select();

    final assignments = rows
        .map((r) => StudentFeeAssignment.fromJson(Map<String, dynamic>.from(r)))
        .toList();

    if (installmentCount != null && installmentCount > 1) {
      final installmentRows = <Map<String, dynamic>>[];
      for (final a in assignments) {
        final amounts =
            splitInstallments(a.amount, installmentCount);
        final dates = installmentDueDates(
          startDate: dueDate,
          parts: installmentCount,
          frequency: a.frequency,
        );
        for (var i = 0; i < installmentCount; i++) {
          installmentRows.add({
            if (scope.tenantId != null) 'tenant_id': scope.tenantId,
            'student_id': studentId,
            'fee_assignment_id': a.id,
            'installment_number': i + 1,
            'total_installments': installmentCount,
            'amount': amounts[i],
            'due_date': _dateOnly(dates[i]),
            'status': 'pending',
          });
        }
      }
      if (installmentRows.isNotEmpty) {
        await _client.from('fee_installments').insert(installmentRows);
      }
    }

    return assignments;
  }

  /// Records a payment against an assignment, updates paid amounts/status,
  /// applies the cash against open installments, optionally marks an invoice
  /// paid, and posts a balanced journal (Dr Cash / Cr Fee income).
  Future<PaymentResult> recordAssignmentPayment({
    required String assignmentId,
    required double amount,
    required String paymentMethod,
    DateTime? paymentDate,
    String? notes,
    String? invoiceId,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('Payment amount must be greater than zero.');
    }
    final scope = await _scope();

    final aRows = await _client
        .from('student_fee_assignments')
        .select()
        .eq('id', assignmentId)
        .limit(1);
    if (aRows.isEmpty) {
      throw StateError('Fee assignment not found.');
    }
    final a = StudentFeeAssignment.fromJson(Map<String, dynamic>.from(aRows.first));
    if (a.status == 'waived' || a.status == 'cancelled') {
      throw StateError('Cannot pay a ${a.status} fee.');
    }
    if (amount > a.outstandingAmount + 0.001) {
      throw StateError(
        'Amount exceeds the outstanding balance of ${a.outstandingAmount}.',
      );
    }

    final studentRows = await _client
        .from('students')
        .select('full_name')
        .eq('id', a.studentId ?? '')
        .limit(1);
    final studentName = studentRows.isNotEmpty
        ? (studentRows.first['full_name'] as String?) ?? 'Student'
        : 'Student';

    // Resolve fee category (e.g. 'tuition') so the income side of the
    // journal can be mapped to the correct chart account.
    var feeCategory = 'other';
    if (a.feeTypeId != null && a.feeTypeId!.isNotEmpty) {
      try {
        final ft = await _client
            .from('fee_types')
            .select('category')
            .eq('id', a.feeTypeId!)
            .limit(1);
        if (ft.isNotEmpty && ft.first['category'] != null) {
          feeCategory = ft.first['category'] as String;
        }
      } catch (_) {}
    }

    final date = paymentDate ?? DateTime.now();
    final now = DateTime.now();
    final paymentNumber =
        'PAY-${now.year}${_two(now.month)}${_two(now.day)}-${now.microsecondsSinceEpoch}';

    final payRows = await _client
        .from('payments')
        .insert({
          if (scope.tenantId != null) 'tenant_id': scope.tenantId,
          'student_id': a.studentId,
          if (invoiceId != null) 'invoice_id': invoiceId,
          'payment_number': paymentNumber,
          'amount': money2(amount),
          'payment_method': _normalizeMethod(paymentMethod),
          'payment_date': _dateOnly(date),
          'payment_type': 'fee',
          'status': 'completed',
          if (scope.userId.isNotEmpty) 'collected_by': scope.userId,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        })
        .select();
    final paymentId = payRows.first['id'] as String;

    // Assignment paid amount + status.
    final newPaid = money2(a.paidAmount + amount);
    final newStatus = (newPaid >= a.amount - 0.001)
        ? 'paid'
        : (newPaid > 0 ? 'partial' : a.status);
    await _client
        .from('student_fee_assignments')
        .update({
          'paid_amount': newPaid,
          'status': newStatus,
          'updated_at': now.toUtc().toIso8601String(),
        })
        .eq('id', assignmentId);

    // Apply cash to the earliest open installments of this assignment.
    await _applyToInstallments(assignmentId, amount, paymentId, date, scope.tenantId);

    // Invoice tracking (if this payment targets an invoice). Best-effort:
    // the payment itself is the source of truth.
    var invoiceNumber = '';
    if (invoiceId != null && invoiceId.isNotEmpty) {
      try {
        invoiceNumber = await _applyToInvoice(invoiceId, amount);
      } catch (e) {
        debugPrint('FeeRepository: invoice update failed (payment kept): $e');
      }
    }

    // Receipt row (number auto-generated by DB trigger when present).
    String? receiptId;
    try {
      final rRows = await _client
          .from('receipts')
          .insert({
            if (scope.tenantId != null) 'tenant_id': scope.tenantId,
            if (invoiceId != null) 'invoice_id': invoiceId,
            'payment_id': paymentId,
            'student_id': a.studentId,
            'receipt_date': _dateOnly(date),
            'amount': money2(amount),
            'payment_method': _normalizeMethod(paymentMethod),
            'description': 'Fee payment — $studentName',
            if (scope.userId.isNotEmpty) 'created_by': scope.userId,
          })
          .select();
      receiptId = rRows.isNotEmpty ? rRows.first['id'] as String? : null;
    } catch (_) {
      // The receipts table (or its trigger) may be unavailable — non-fatal.
    }

    // Balanced double-entry journal (Phase 1 core, guide §3.1 step 6).
    // Never let a journal failure roll back a payment that was already
    // recorded and applied to the assignment.
    String? journalId;
    try {
      journalId = await _journal.postJournal(
        tenantId: scope.tenantId ?? a.tenantId ?? '',
        date: date,
        description: 'Fee payment — $studentName',
        lines: [
          JournalLine.debit(cashAccountCodeForMethod(paymentMethod), amount),
          JournalLine.credit(
            incomeAccountCodeForCategory(feeCategory),
            amount,
            description: 'Student fee collection',
          ),
        ],
        referenceType: 'payment',
        referenceId: paymentId,
        createdBy: scope.userId.isEmpty ? null : scope.userId,
      );
    } catch (e) {
      debugPrint('FeeRepository: journal post failed (payment kept): $e');
    }

    // Link the journal and receipt back to the payment row.
    try {
      await _client
          .from('payments')
          .update({
            if (journalId != null) 'journal_id': journalId,
            if (receiptId != null) 'receipt_id': receiptId,
            'updated_at': now.toUtc().toIso8601String(),
          })
          .eq('id', paymentId);
    } catch (_) {}

    return PaymentResult(
      paymentId: paymentId,
      journalId: journalId,
      receiptId: receiptId,
      invoiceNumber: invoiceNumber,
      paidSoFar: newPaid,
    );
  }

  Future<void> _applyToInstallments(
    String assignmentId,
    double amount,
    String paymentId,
    DateTime date,
    String? tenantId,
  ) async {
    try {
      final pending = await _client
          .from('fee_installments')
          .select()
          .eq('fee_assignment_id', assignmentId)
          .inFilter('status', ['pending', 'partial'])
          .order('installment_number');
      var remaining = amount;
      for (final row in pending) {
        if (remaining <= 0.001) break;
        final inst = FeeInstallment.fromJson(Map<String, dynamic>.from(row));
        final take = money2(inst.outstandingAmount < remaining
            ? inst.outstandingAmount
            : remaining);
        if (take <= 0) continue;
        final newInstPaid = money2(inst.paidAmount + take);
        final fullyPaid = newInstPaid >= inst.amount - 0.001;
        await _client
            .from('fee_installments')
            .update({
              'paid_amount': newInstPaid,
              if (fullyPaid) 'status': 'paid',
              if (fullyPaid) 'paid_date': _dateOnly(date),
              if (fullyPaid) 'payment_id': paymentId,
            })
            .eq('id', inst.id);
        remaining = money2(remaining - take);
      }
    } catch (_) {
      // Installment bookkeeping is best-effort; assignment amount still updated.
    }
  }

  Future<String> _applyToInvoice(String invoiceId, double amount) async {
    final now = DateTime.now();
    await _client
        .from('invoices')
        .update({'paid_amount': money2(amount), 'updated_at': now.toUtc().toIso8601String()})
        .eq('id', invoiceId);
    String number = '';
    try {
      final rows = await _client
          .from('invoices')
          .select('invoice_number, outstanding_amount, status')
          .eq('id', invoiceId)
          .limit(1);
      if (rows.isNotEmpty) {
        final r = rows.first;
        number = (r['invoice_number'] as String?) ?? '';
        final outstanding = ((r['outstanding_amount'] as num?) ?? 0).toDouble();
        if (outstanding <= 0.001) {
          await _client
              .from('invoices')
              .update({
                'status': 'paid',
                'paid_date': _dateOnly(now),
                'updated_at': now.toUtc().toIso8601String(),
              })
              .eq('id', invoiceId);
        }
      }
    } catch (_) {}
    return number;
  }

  /// Creates an invoice from one or more (already assigned) fees.
  Future<Map<String, dynamic>> createInvoiceFromAssignments({
    required String studentId,
    required List<StudentFeeAssignment> assignments,
    double discountAmount = 0,
    double taxAmount = 0,
    String? discountReason,
    String? description,
    DateTime? dueDate,
  }) async {
    if (assignments.isEmpty) {
      throw ArgumentError('Select at least one fee assignment.');
    }
    final scope = await _scope();
    final now = DateTime.now();
    final gross = assignments.fold<double>(0, (s, a) => s + a.amount);

    final rows = await _client
        .from('invoices')
        .insert({
          if (scope.tenantId != null) 'tenant_id': scope.tenantId,
          'student_id': studentId,
          'invoice_number':
              'INV-${now.year}${_two(now.month)}${_two(now.day)}-${now.microsecondsSinceEpoch}',
          'amount': money2(gross),
          'due_date': _dateOnly(dueDate ?? now.add(const Duration(days: 15))),
          'issue_date': _dateOnly(now),
          'status': 'pending',
          'discount_amount': money2(discountAmount),
          if (discountReason != null && discountReason.isNotEmpty)
            'discount_reason': discountReason,
          'tax_amount': money2(taxAmount),
          'items': [
            for (final a in assignments)
              {
                'assignment_id': a.id,
                'description': a.structureName ?? 'Fee',
                'amount': a.amount,
              },
          ],
          if (description != null && description.isNotEmpty)
            'description': description,
          if (scope.userId.isNotEmpty) 'created_by': scope.userId,
        })
        .select();
    return Map<String, dynamic>.from(rows.first);
  }

  /// Waives an assignment with a mandatory reason.
  Future<void> waiveAssignment({
    required String assignmentId,
    required String reason,
  }) async {
    final scope = await _scope();
    final now = DateTime.now();
    await _client
        .from('student_fee_assignments')
        .update({
          'status': 'waived',
          'waived_by': scope.userId.isEmpty ? null : scope.userId,
          'waived_at': now.toUtc().toIso8601String(),
          'waiver_reason': reason,
          'updated_at': now.toUtc().toIso8601String(),
        })
        .eq('id', assignmentId);
  }

  // --------------------------------------------------------------------------
  // Picker helpers
  // --------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> listStudents() async {
    return _client
        .from('students')
        .select('id, full_name, student_code')
        .order('full_name');
  }

  Future<List<Map<String, dynamic>>> listPrograms() async {
    return _client.from('programs').select('id, name').order('name');
  }

  Future<List<Map<String, dynamic>>> listClasses() async {
    return _client.from('classes').select('id, name').order('name');
  }

  // --------------------------------------------------------------------------
  // Private helpers
  // --------------------------------------------------------------------------

  Future<Map<String, String>> _fetchFeeTypeMap() async {
    final rows = await _client.from('fee_types').select('id, name, category');
    return {
      for (final r in rows)
        (r['id'] as String): (r['name'] as String?) ?? '',
    };
  }

  Future<Map<String, String>> _fetchFeeStructureMap() async {
    final rows = await _client.from('fee_structures').select('id, name');
    return {
      for (final r in rows) (r['id'] as String): (r['name'] as String?) ?? '',
    };
  }

  Future<Map<String, String>> _fetchStudentMap() async {
    final rows = await _client.from('students').select('id, full_name');
    return {
      for (final r in rows)
        (r['id'] as String): (r['full_name'] as String?) ?? '',
    };
  }

  Future<Map<String, String>> _fetchNameMap(String table) async {
    try {
      final rows = await _client.from(table).select('id, name').limit(500);
      return {
        for (final r in rows) (r['id'] as String): (r['name'] as String?) ?? '',
      };
    } catch (_) {
      return {};
    }
  }

  static String _normalizeMethod(String method) {
    switch (method.toLowerCase().replaceAll(' ', '_')) {
      case 'cash':
      case 'card':
      case 'bank_transfer':
      case 'online':
      case 'check':
      case 'mobile_payment':
        return method.toLowerCase().replaceAll(' ', '_');
      default:
        return 'cash';
    }
  }

  static String _dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _two(int n) => n.toString().padLeft(2, '0');
}
