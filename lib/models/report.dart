enum ReportType { attendance, grade, payment, performance }

class Report {
  final String id;
  final String studentId;
  final String studentName;
  final ReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final Map<String, dynamic> data;
  final DateTime generatedAt;

  Report({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.data,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'studentName': studentName,
    'type': type.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'data': data,
    'generatedAt': generatedAt.toIso8601String(),
  };

  factory Report.fromJson(Map<String, dynamic> json) => Report(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    studentName: json['studentName'] as String,
    type: ReportType.values.firstWhere((e) => e.name == json['type']),
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    data: json['data'] as Map<String, dynamic>,
    generatedAt: DateTime.parse(json['generatedAt']),
  );
}
