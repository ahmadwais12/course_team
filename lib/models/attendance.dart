enum AttendanceStatus { present, absent, late, leave }

class Attendance {
  final String id;
  final String studentId;
  final String classId;
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;
  final DateTime createdAt;

  Attendance({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.date,
    required this.status,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'classId': classId,
    'date': date.toIso8601String(),
    'status': status.name,
    'notes': notes,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Attendance.fromJson(Map<String, dynamic> json) => Attendance(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    classId: json['classId'] as String,
    date: DateTime.parse(json['date']),
    status: AttendanceStatus.values.firstWhere((e) => e.name == json['status']),
    notes: json['notes'] as String?,
    createdAt: DateTime.parse(json['createdAt']),
  );

  Attendance copyWith({
    String? id,
    String? studentId,
    String? classId,
    DateTime? date,
    AttendanceStatus? status,
    String? notes,
    DateTime? createdAt,
  }) => Attendance(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    classId: classId ?? this.classId,
    date: date ?? this.date,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
}

class Grade {
  final String id;
  final String studentId;
  final String classId;
  final List<double> quizzes;
  final List<double> homework;
  final double? midterm;
  final double? finalExam;
  final double attendanceScore;
  final double totalScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grade({
    required this.id,
    required this.studentId,
    required this.classId,
    required this.quizzes,
    required this.homework,
    this.midterm,
    this.finalExam,
    required this.attendanceScore,
    required this.totalScore,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'classId': classId,
    'quizzes': quizzes,
    'homework': homework,
    'midterm': midterm,
    'finalExam': finalExam,
    'attendanceScore': attendanceScore,
    'totalScore': totalScore,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Grade.fromJson(Map<String, dynamic> json) => Grade(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    classId: json['classId'] as String,
    quizzes: List<double>.from(json['quizzes'] ?? []),
    homework: List<double>.from(json['homework'] ?? []),
    midterm: json['midterm'] != null ? (json['midterm'] as num).toDouble() : null,
    finalExam: json['finalExam'] != null ? (json['finalExam'] as num).toDouble() : null,
    attendanceScore: (json['attendanceScore'] as num).toDouble(),
    totalScore: (json['totalScore'] as num).toDouble(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Grade copyWith({
    String? id,
    String? studentId,
    String? classId,
    List<double>? quizzes,
    List<double>? homework,
    double? midterm,
    double? finalExam,
    double? attendanceScore,
    double? totalScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Grade(
    id: id ?? this.id,
    studentId: studentId ?? this.studentId,
    classId: classId ?? this.classId,
    quizzes: quizzes ?? this.quizzes,
    homework: homework ?? this.homework,
    midterm: midterm ?? this.midterm,
    finalExam: finalExam ?? this.finalExam,
    attendanceScore: attendanceScore ?? this.attendanceScore,
    totalScore: totalScore ?? this.totalScore,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
