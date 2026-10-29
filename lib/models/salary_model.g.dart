// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'salary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Salary _$SalaryFromJson(Map<String, dynamic> json) => Salary(
      id: json['id'] as String,
      employeeId: json['employee_id'] as String,
      employeeType: json['employee_type'] as String?,
      month: (json['month'] as num).toInt(),
      year: (json['year'] as num).toInt(),
      basicSalary: (json['basic_salary'] as num).toDouble(),
      allowances: json['allowances'] as Map<String, dynamic>?,
      deductions: json['deductions'] as Map<String, dynamic>?,
      bonus: (json['bonus'] as num?)?.toDouble() ?? 0,
      overtimeHours: (json['overtime_hours'] as num?)?.toInt() ?? 0,
      overtimePay: (json['overtime_pay'] as num?)?.toDouble() ?? 0,
      grossSalary: (json['gross_salary'] as num?)?.toDouble(),
      netSalary: (json['net_salary'] as num?)?.toDouble(),
      paymentDate: json['payment_date'] == null
          ? null
          : DateTime.parse(json['payment_date'] as String),
      paymentMethod: json['payment_method'] as String?,
      status: json['status'] as String? ?? 'pending',
      payslipUrl: json['payslip_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$SalaryToJson(Salary instance) => <String, dynamic>{
      'id': instance.id,
      'employee_id': instance.employeeId,
      'employee_type': instance.employeeType,
      'month': instance.month,
      'year': instance.year,
      'basic_salary': instance.basicSalary,
      'allowances': instance.allowances,
      'deductions': instance.deductions,
      'bonus': instance.bonus,
      'overtime_hours': instance.overtimeHours,
      'overtime_pay': instance.overtimePay,
      'gross_salary': instance.grossSalary,
      'net_salary': instance.netSalary,
      'payment_date': instance.paymentDate?.toIso8601String(),
      'payment_method': instance.paymentMethod,
      'status': instance.status,
      'payslip_url': instance.payslipUrl,
      'notes': instance.notes,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
