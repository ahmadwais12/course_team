enum ExamType { placement, midterm, final_, quiz, practice }
enum ExamStatus { scheduled, ongoing, completed, cancelled }

class Exam {
  final String id;
  final String courseId;
  final String courseName;
  final String title;
  final ExamType type;
  final ExamStatus status;
  final DateTime scheduledDate;
  final int durationMinutes;
  final int totalMarks;
  final String? description;
  final DateTime createdAt;

  Exam({
    required this.id,
    required this.courseId,
    required this.courseName,
    required this.title,
    required this.type,
    required this.status,
    required this.scheduledDate,
    required this.durationMinutes,
    required this.totalMarks,
    this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'courseName': courseName,
    'title': title,
    'type': type.name,
    'status': status.name,
    'scheduledDate': scheduledDate.toIso8601String(),
    'durationMinutes': durationMinutes,
    'totalMarks': totalMarks,
    'description': description,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Exam.fromJson(Map<String, dynamic> json) => Exam(
    id: json['id'] as String,
    courseId: json['courseId'] as String,
    courseName: json['courseName'] as String,
    title: json['title'] as String,
    type: ExamType.values.firstWhere((e) => e.name == json['type']),
    status: ExamStatus.values.firstWhere((e) => e.name == json['status']),
    scheduledDate: DateTime.parse(json['scheduledDate']),
    durationMinutes: json['durationMinutes'] as int,
    totalMarks: json['totalMarks'] as int,
    description: json['description'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Exam copyWith({
    String? id,
    String? courseId,
    String? courseName,
    String? title,
    ExamType? type,
    ExamStatus? status,
    DateTime? scheduledDate,
    int? durationMinutes,
    int? totalMarks,
    String? description,
    DateTime? createdAt,
  }) => Exam(
    id: id ?? this.id,
    courseId: courseId ?? this.courseId,
    courseName: courseName ?? this.courseName,
    title: title ?? this.title,
    type: type ?? this.type,
    status: status ?? this.status,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    durationMinutes: durationMinutes ?? this.durationMinutes,
    totalMarks: totalMarks ?? this.totalMarks,
    description: description ?? this.description,
    createdAt: createdAt ?? this.createdAt,
  );
}

class ExamResult {
  final String id;
  final String examId;
  final String studentId;
  final String studentName;
  final int marksObtained;
  final int totalMarks;
  final double percentage;
  final String grade;
  final DateTime submittedAt;

  ExamResult({
    required this.id,
    required this.examId,
    required this.studentId,
    required this.studentName,
    required this.marksObtained,
    required this.totalMarks,
    required this.percentage,
    required this.grade,
    required this.submittedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'examId': examId,
    'studentId': studentId,
    'studentName': studentName,
    'marksObtained': marksObtained,
    'totalMarks': totalMarks,
    'percentage': percentage,
    'grade': grade,
    'submittedAt': submittedAt.toIso8601String(),
  };

  factory ExamResult.fromJson(Map<String, dynamic> json) => ExamResult(
    id: json['id'] as String,
    examId: json['examId'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    marksObtained: json['marksObtained'] as int,
    totalMarks: json['totalMarks'] as int,
    percentage: (json['percentage'] as num).toDouble(),
    grade: json['grade'] as String,
    submittedAt: DateTime.parse(json['submittedAt']),
  );
}
