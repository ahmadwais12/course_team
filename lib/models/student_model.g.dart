// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Student _$StudentFromJson(Map<String, dynamic> json) => Student(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      grade: json['grade'] as String,
      section: json['section'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      parentId: json['parent_id'] as String,
      status: json['status'] as String,
      photoUrl: json['photo_url'] as String?,
      enrollmentDate: json['enrollment_date'] == null
          ? null
          : DateTime.parse(json['enrollment_date'] as String),
      enrolledCourses: (json['enrolled_courses'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      attendancePercentage:
          (json['attendance_percentage'] as num?)?.toDouble() ?? 0.0,
      averageGrade: (json['average_grade'] as num?)?.toDouble() ?? 0.0,
    );

Map<String, dynamic> _$StudentToJson(Student instance) => <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'phone': instance.phone,
      'grade': instance.grade,
      'section': instance.section,
      'date_of_birth': instance.dateOfBirth.toIso8601String(),
      'parent_id': instance.parentId,
      'status': instance.status,
      'photo_url': instance.photoUrl,
      'enrollment_date': instance.enrollmentDate?.toIso8601String(),
      'enrolled_courses': instance.enrolledCourses,
      'attendance_percentage': instance.attendancePercentage,
      'average_grade': instance.averageGrade,
    };

StudentAttendance _$StudentAttendanceFromJson(Map<String, dynamic> json) =>
    StudentAttendance(
      studentId: json['student_id'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      courseId: json['course_id'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$StudentAttendanceToJson(StudentAttendance instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'date': instance.date.toIso8601String(),
      'status': instance.status,
      'course_id': instance.courseId,
      'notes': instance.notes,
    };

StudentGrade _$StudentGradeFromJson(Map<String, dynamic> json) => StudentGrade(
      studentId: json['student_id'] as String,
      courseId: json['course_id'] as String,
      examId: json['exam_id'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['max_score'] as num).toDouble(),
      grade: json['grade'] as String,
      remarks: json['remarks'] as String?,
      date:
          json['date'] == null ? null : DateTime.parse(json['date'] as String),
    );

Map<String, dynamic> _$StudentGradeToJson(StudentGrade instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'course_id': instance.courseId,
      'exam_id': instance.examId,
      'score': instance.score,
      'max_score': instance.maxScore,
      'grade': instance.grade,
      'remarks': instance.remarks,
      'date': instance.date?.toIso8601String(),
    };
