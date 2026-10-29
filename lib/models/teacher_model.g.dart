// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teacher_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Teacher _$TeacherFromJson(Map<String, dynamic> json) => Teacher(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      subject: json['subject'] as String,
      qualification: json['qualification'] as String,
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String,
      photoUrl: json['photo_url'] as String?,
      salary: (json['salary'] as num?)?.toDouble() ?? 0.0,
      assignedClasses: (json['assigned_classes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$TeacherToJson(Teacher instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'subject': instance.subject,
      'qualification': instance.qualification,
      'join_date': instance.joinDate.toIso8601String(),
      'status': instance.status,
      'photo_url': instance.photoUrl,
      'salary': instance.salary,
      'assigned_classes': instance.assignedClasses,
      'rating': instance.rating,
    };

TeacherAttendance _$TeacherAttendanceFromJson(Map<String, dynamic> json) =>
    TeacherAttendance(
      teacherId: json['teacher_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$TeacherAttendanceToJson(TeacherAttendance instance) =>
    <String, dynamic>{
      'teacher_id': instance.teacherId,
      'date': instance.date.toIso8601String(),
      'status': instance.status,
      'notes': instance.notes,
    };
