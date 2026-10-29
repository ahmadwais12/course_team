enum SalaryType { fixed, hourly, perStudent }

class Teacher {
  final String id;
  final String userId;
  final String departmentId;
  final List<String> classIds;
  final SalaryType salaryType;
  final double salaryAmount;
  final bool isActive;
  final DateTime createdAt;

  Teacher({
    required this.id,
    required this.userId,
    required this.departmentId,
    required this.classIds,
    required this.salaryType,
    required this.salaryAmount,
    required this.isActive,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'departmentId': departmentId,
    'classIds': classIds,
    'salaryType': salaryType.name,
    'salaryAmount': salaryAmount,
    'isActive': isActive,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
    id: json['id'] as String,
    userId: json['userId'] as String,
    departmentId: json['departmentId'] as String,
    classIds: List<String>.from(json['classIds'] ?? []),
    salaryType: SalaryType.values.firstWhere((e) => e.name == json['salaryType']),
    salaryAmount: (json['salaryAmount'] as num).toDouble(),
    isActive: json['isActive'] as bool,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Teacher copyWith({
    String? id,
    String? userId,
    String? departmentId,
    List<String>? classIds,
    SalaryType? salaryType,
    double? salaryAmount,
    bool? isActive,
    DateTime? createdAt,
  }) => Teacher(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    departmentId: departmentId ?? this.departmentId,
    classIds: classIds ?? this.classIds,
    salaryType: salaryType ?? this.salaryType,
    salaryAmount: salaryAmount ?? this.salaryAmount,
    isActive: isActive ?? this.isActive,
    createdAt: createdAt ?? this.createdAt,
  );
}

enum PayrollStatus { pending, paid }

class Payroll {
  final String id;
  final String teacherId;
  final double baseSalary;
  final List<double> bonuses;
  final List<double> deductions;
  final double netSalary;
  final String period;
  final PayrollStatus status;
  final DateTime? paidDate;
  final DateTime createdAt;

  Payroll({
    required this.id,
    required this.teacherId,
    required this.baseSalary,
    required this.bonuses,
    required this.deductions,
    required this.netSalary,
    required this.period,
    required this.status,
    this.paidDate,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'teacher_id': teacherId,
        'base_salary': baseSalary,
        'bonuses': bonuses,
        'deductions_list': deductions,
        'net_salary': netSalary,
        'period': period,
        'name': 'Payroll $period',
        'status': status.name,
        'paid_date': paidDate?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };

  factory Payroll.fromJson(Map<String, dynamic> json) {
    final statusRaw = (json['status'] ?? 'pending').toString();
    final status = PayrollStatus.values.firstWhere(
      (e) => e.name == statusRaw,
      orElse: () => statusRaw == 'completed' || statusRaw == 'approved'
          ? PayrollStatus.paid
          : PayrollStatus.pending,
    );
    final bonusesRaw = json['bonuses'];
    final deductionsRaw = json['deductions_list'] ?? json['deductions'];
    return Payroll(
      id: json['id'] as String,
      teacherId: (json['teacher_id'] ?? json['teacherId'] ?? '') as String,
      baseSalary: ((json['base_salary'] ?? json['baseSalary'] ?? 0) as num).toDouble(),
      bonuses: bonusesRaw is List
          ? bonusesRaw.map((e) => (e as num).toDouble()).toList()
          : <double>[],
      deductions: deductionsRaw is List
          ? deductionsRaw.map((e) => (e as num).toDouble()).toList()
          : <double>[],
      netSalary: ((json['net_salary'] ?? json['netSalary'] ?? json['total_net'] ?? 0) as num)
          .toDouble(),
      period: (json['period'] ?? json['payroll_period'] ?? '') as String,
      status: status,
      paidDate: (json['paid_date'] ?? json['paidDate'] ?? json['pay_date']) != null
          ? DateTime.parse(
              (json['paid_date'] ?? json['paidDate'] ?? json['pay_date']).toString())
          : null,
      createdAt: DateTime.parse(
          (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String())
              .toString()),
    );
  }

  Payroll copyWith({
    String? id,
    String? teacherId,
    double? baseSalary,
    List<double>? bonuses,
    List<double>? deductions,
    double? netSalary,
    String? period,
    PayrollStatus? status,
    DateTime? paidDate,
    DateTime? createdAt,
  }) => Payroll(
    id: id ?? this.id,
    teacherId: teacherId ?? this.teacherId,
    baseSalary: baseSalary ?? this.baseSalary,
    bonuses: bonuses ?? this.bonuses,
    deductions: deductions ?? this.deductions,
    netSalary: netSalary ?? this.netSalary,
    period: period ?? this.period,
    status: status ?? this.status,
    paidDate: paidDate ?? this.paidDate,
    createdAt: createdAt ?? this.createdAt,
  );
}
