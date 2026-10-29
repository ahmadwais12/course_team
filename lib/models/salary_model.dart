import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'salary_model.g.dart';

@JsonSerializable()
class Salary {
  final String id;
  @JsonKey(name: 'employee_id')
  final String employeeId;
  @JsonKey(name: 'employee_type')
  final String? employeeType; // 'teacher', 'staff'
  final int month;
  final int year;
  @JsonKey(name: 'basic_salary')
  final double basicSalary;
  final Map<String, dynamic>? allowances;
  final Map<String, dynamic>? deductions;
  final double bonus;
  @JsonKey(name: 'overtime_hours')
  final int overtimeHours;
  @JsonKey(name: 'overtime_pay')
  final double overtimePay;
  @JsonKey(name: 'gross_salary')
  final double? grossSalary;
  @JsonKey(name: 'net_salary')
  final double? netSalary;
  @JsonKey(name: 'payment_date')
  final DateTime? paymentDate;
  @JsonKey(name: 'payment_method')
  final String? paymentMethod;
  final String? status; // 'pending', 'processed', 'paid', 'cancelled'
  @JsonKey(name: 'payslip_url')
  final String? payslipUrl;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  Salary({
    required this.id,
    required this.employeeId,
    this.employeeType,
    required this.month,
    required this.year,
    required this.basicSalary,
    this.allowances,
    this.deductions,
    this.bonus = 0,
    this.overtimeHours = 0,
    this.overtimePay = 0,
    this.grossSalary,
    this.netSalary,
    this.paymentDate,
    this.paymentMethod,
    this.status = 'pending',
    this.payslipUrl,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Salary.fromJson(Map<String, dynamic> json) => _$SalaryFromJson(json);
  Map<String, dynamic> toJson() => _$SalaryToJson(this);

  bool get isPending => status == 'pending';
  bool get isProcessed => status == 'processed';
  bool get isPaid => status == 'paid';
  bool get isCancelled => status == 'cancelled';

  double get calculatedGross {
    double totalAllowances = 0;
    if (allowances != null) {
      allowances!.forEach((key, value) {
        totalAllowances += (value as num).toDouble();
      });
    }
    return basicSalary + totalAllowances + bonus + overtimePay;
  }

  double get calculatedNet {
    double totalDeductions = 0;
    if (deductions != null) {
      deductions!.forEach((key, value) {
        totalDeductions += (value as num).toDouble();
      });
    }
    return calculatedGross - totalDeductions;
  }

  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'processed':
        return Colors.blue;
      case 'paid':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String get monthName {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
