class Certificate {
  final String id;
  final String studentId;
  final String programId;
  final String classId;
  final double finalGrade;
  final DateTime issueDate;
  final String certificateNumber;

  Certificate({
    required this.id,
    required this.studentId,
    required this.programId,
    required this.classId,
    required this.finalGrade,
    required this.issueDate,
    required this.certificateNumber,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'studentId': studentId,
    'programId': programId,
    'classId': classId,
    'finalGrade': finalGrade,
    'issueDate': issueDate.toIso8601String(),
    'certificateNumber': certificateNumber,
  };

  factory Certificate.fromJson(Map<String, dynamic> json) => Certificate(
    id: json['id'] as String,
    studentId: json['studentId'] as String,
    programId: json['programId'] as String,
    classId: json['classId'] as String,
    finalGrade: (json['finalGrade'] as num).toDouble(),
    issueDate: DateTime.parse(json['issueDate']),
    certificateNumber: json['certificateNumber'] as String,
  );
}
