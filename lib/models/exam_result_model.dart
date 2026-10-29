import 'package:json_annotation/json_annotation.dart';

part 'exam_result_model.g.dart';

@JsonSerializable()
class ExamResultModel {
  final String id;
  final String? studentId;
  final String examName;
  final String? subject;
  final double score;
  final double? maxScore;
  final double? percentage;
  final String? grade;
  @JsonKey(fromJson: _dateFromJson, toJson: _dateToJson)
  final DateTime? examDate;
  final String? classId;
  final String? teacherId;
  final String? comments;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime updatedAt;

  ExamResultModel({
    required this.id,
    this.studentId,
    required this.examName,
    this.subject,
    required this.score,
    this.maxScore = 100,
    this.percentage,
    this.grade,
    this.examDate,
    this.classId,
    this.teacherId,
    this.comments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExamResultModel.fromJson(Map<String, dynamic> json) =>
      _$ExamResultModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExamResultModelToJson(this);

  // Helper getters
  double get calculatedPercentage {
    final max = maxScore ?? 100;
    return (score / max) * 100;
  }

  String get calculatedGrade {
    final pct = percentage ?? calculatedPercentage;
    if (pct >= 90) return 'A+';
    if (pct >= 85) return 'A';
    if (pct >= 80) return 'A-';
    if (pct >= 75) return 'B+';
    if (pct >= 70) return 'B';
    if (pct >= 65) return 'B-';
    if (pct >= 60) return 'C+';
    if (pct >= 55) return 'C';
    if (pct >= 50) return 'C-';
    if (pct >= 45) return 'D+';
    if (pct >= 40) return 'D';
    return 'F';
  }

  String get status {
    final pct = percentage ?? calculatedPercentage;
    if (pct >= 50) return 'Passed';
    return 'Failed';
  }

  bool get isPassed => (percentage ?? calculatedPercentage) >= 50;

  // DateTime helpers
  static DateTime? _dateFromJson(dynamic value) {
    if (value == null) return null;
    if (value is String) return DateTime.parse(value);
    return null;
  }

  static String? _dateToJson(DateTime? value) => value?.toIso8601String();

  static DateTime _dateTimeFromJson(dynamic value) {
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  static String? _dateTimeToJson(DateTime? value) => value?.toIso8601String();

  ExamResultModel copyWith({
    String? id,
    String? studentId,
    String? examName,
    String? subject,
    double? score,
    double? maxScore,
    double? percentage,
    String? grade,
    DateTime? examDate,
    String? classId,
    String? teacherId,
    String? comments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExamResultModel(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      examName: examName ?? this.examName,
      subject: subject ?? this.subject,
      score: score ?? this.score,
      maxScore: maxScore ?? this.maxScore,
      percentage: percentage ?? this.percentage,
      grade: grade ?? this.grade,
      examDate: examDate ?? this.examDate,
      classId: classId ?? this.classId,
      teacherId: teacherId ?? this.teacherId,
      comments: comments ?? this.comments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
