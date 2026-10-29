import 'package:json_annotation/json_annotation.dart';

part 'teacher_model.g.dart';

@JsonSerializable()
class Teacher {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String email;
  final String phone;
  final String subject;
  final String qualification;
  @JsonKey(name: 'join_date')
  final DateTime joinDate;
  final String status;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  final double salary;
  @JsonKey(name: 'assigned_classes')
  final List<String> assignedClasses;
  final double rating;

  Teacher({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.subject,
    required this.qualification,
    required this.joinDate,
    required this.status,
    this.photoUrl,
    this.salary = 0.0,
    this.assignedClasses = const [],
    this.rating = 0.0,
  });

  String get fullName => '$firstName $lastName';

  factory Teacher.fromJson(Map<String, dynamic> json) => _$TeacherFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherToJson(this);
}

@JsonSerializable()
class TeacherAttendance {
  @JsonKey(name: 'teacher_id')
  final String teacherId;
  final DateTime date;
  final String status;
  final String? notes;

  TeacherAttendance({
    required this.teacherId,
    required this.date,
    required this.status,
    this.notes,
  });

  factory TeacherAttendance.fromJson(Map<String, dynamic> json) => _$TeacherAttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$TeacherAttendanceToJson(this);
}
