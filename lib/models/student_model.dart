import 'package:json_annotation/json_annotation.dart';

part 'student_model.g.dart';

@JsonSerializable()
class Student {
  final String id;
  @JsonKey(name: 'first_name')
  final String firstName;
  @JsonKey(name: 'last_name')
  final String lastName;
  final String email;
  final String phone;
  final String grade;
  final String section;
  @JsonKey(name: 'date_of_birth')
  final DateTime dateOfBirth;
  @JsonKey(name: 'parent_id')
  final String parentId;
  final String status;
  @JsonKey(name: 'photo_url')
  final String? photoUrl;
  @JsonKey(name: 'enrollment_date')
  final DateTime? enrollmentDate;
  @JsonKey(name: 'enrolled_courses')
  final List<String> enrolledCourses;
  @JsonKey(name: 'attendance_percentage')
  final double attendancePercentage;
  @JsonKey(name: 'average_grade')
  final double averageGrade;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.grade,
    required this.section,
    required this.dateOfBirth,
    required this.parentId,
    required this.status,
    this.photoUrl,
    this.enrollmentDate,
    this.enrolledCourses = const [],
    this.attendancePercentage = 0.0,
    this.averageGrade = 0.0,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromJson(Map<String, dynamic> json) =>
      _$StudentFromJson(json);
  Map<String, dynamic> toJson() => _$StudentToJson(this);
}

@JsonSerializable()
class StudentAttendance {
  @JsonKey(name: 'student_id')
  final String studentId;
  final DateTime date;
  final String status;
  @JsonKey(name: 'course_id')
  final String? courseId;
  final String? notes;

  StudentAttendance({
    required this.studentId,
    required this.date,
    required this.status,
    this.courseId,
    this.notes,
  });

  factory StudentAttendance.fromJson(Map<String, dynamic> json) =>
      _$StudentAttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$StudentAttendanceToJson(this);
}

@JsonSerializable()
class StudentGrade {
  @JsonKey(name: 'student_id')
  final String studentId;
  @JsonKey(name: 'course_id')
  final String courseId;
  @JsonKey(name: 'exam_id')
  final String examId;
  final double score;
  @JsonKey(name: 'max_score')
  final double maxScore;
  final String grade;
  final String? remarks;
  final DateTime? date;

  StudentGrade({
    required this.studentId,
    required this.courseId,
    required this.examId,
    required this.score,
    required this.maxScore,
    required this.grade,
    this.remarks,
    this.date,
  });

  double get percentage => (score / maxScore) * 100;

  factory StudentGrade.fromJson(Map<String, dynamic> json) =>
      _$StudentGradeFromJson(json);
  Map<String, dynamic> toJson() => _$StudentGradeToJson(this);
}
