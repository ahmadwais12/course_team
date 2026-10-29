// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certificate_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CertificateModel _$CertificateModelFromJson(Map<String, dynamic> json) =>
    CertificateModel(
      id: json['id'] as String,
      tenantId: json['tenant_id'] as String?,
      studentId: json['student_id'] as String,
      certificateType: json['certificate_type'] as String,
      courseName: json['course_name'] as String?,
      levelAchieved: json['level_achieved'] as String?,
      issueDate: DateTime.parse(json['issue_date'] as String),
      certificateNumber: json['certificate_number'] as String?,
      certificateUrl: json['certificate_url'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
      issuedBy: json['issued_by'] as String?,
      status: json['status'] as String? ?? 'issued',
      notes: json['notes'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CertificateModelToJson(CertificateModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tenant_id': instance.tenantId,
      'student_id': instance.studentId,
      'certificate_type': instance.certificateType,
      'course_name': instance.courseName,
      'level_achieved': instance.levelAchieved,
      'issue_date': instance.issueDate.toIso8601String(),
      'certificate_number': instance.certificateNumber,
      'certificate_url': instance.certificateUrl,
      'qr_code_url': instance.qrCodeUrl,
      'issued_by': instance.issuedBy,
      'status': instance.status,
      'notes': instance.notes,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
