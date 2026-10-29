import 'package:json_annotation/json_annotation.dart';

part 'certificate_model.g.dart';

@JsonSerializable()
class CertificateModel {
  final String id;
  @JsonKey(name: 'tenant_id')
  final String? tenantId;
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'certificate_type')
  final String certificateType;
  @JsonKey(name: 'course_name')
  final String? courseName;
  @JsonKey(name: 'level_achieved')
  final String? levelAchieved;
  @JsonKey(name: 'issue_date')
  final DateTime issueDate;
  @JsonKey(name: 'certificate_number')
  final String? certificateNumber;
  @JsonKey(name: 'certificate_url')
  final String? certificateUrl;
  @JsonKey(name: 'qr_code_url')
  final String? qrCodeUrl;
  @JsonKey(name: 'issued_by')
  final String? issuedBy;
  final String status;
  final String? notes;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  @JsonKey(name: 'updated_at')
  final DateTime? updatedAt;

  CertificateModel({
    required this.id,
    this.tenantId,
    required this.studentId,
    required this.certificateType,
    this.courseName,
    this.levelAchieved,
    required this.issueDate,
    this.certificateNumber,
    this.certificateUrl,
    this.qrCodeUrl,
    this.issuedBy,
    this.status = 'issued',
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory CertificateModel.fromJson(Map<String, dynamic> json) =>
      _$CertificateModelFromJson(json);
  Map<String, dynamic> toJson() => _$CertificateModelToJson(this);
}
