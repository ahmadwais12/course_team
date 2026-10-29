// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam_result_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExamResultModel _$ExamResultModelFromJson(Map<String, dynamic> json) =>
    ExamResultModel(
      id: json['id'] as String,
      studentId: json['studentId'] as String?,
      examName: json['examName'] as String,
      subject: json['subject'] as String?,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num?)?.toDouble() ?? 100,
      percentage: (json['percentage'] as num?)?.toDouble(),
      grade: json['grade'] as String?,
      examDate: ExamResultModel._dateFromJson(json['examDate']),
      classId: json['classId'] as String?,
      teacherId: json['teacherId'] as String?,
      comments: json['comments'] as String?,
      createdAt: ExamResultModel._dateTimeFromJson(json['createdAt']),
      updatedAt: ExamResultModel._dateTimeFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ExamResultModelToJson(ExamResultModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'examName': instance.examName,
      'subject': instance.subject,
      'score': instance.score,
      'maxScore': instance.maxScore,
      'percentage': instance.percentage,
      'grade': instance.grade,
      'examDate': ExamResultModel._dateToJson(instance.examDate),
      'classId': instance.classId,
      'teacherId': instance.teacherId,
      'comments': instance.comments,
      'createdAt': ExamResultModel._dateTimeToJson(instance.createdAt),
      'updatedAt': ExamResultModel._dateTimeToJson(instance.updatedAt),
    };
