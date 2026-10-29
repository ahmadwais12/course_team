enum StudentStatus { active, inactive, suspended, graduated }

class Student {
  final String id;
  final String userId;
  final String programId;
  final int duration;
  final String classId;
  final StudentStatus status;
  final double totalFees;
  final double paidAmount;
  final double discount;
  final DateTime enrollmentDate;
  final DateTime? completionDate;
  final double attendancePercentage;
  final double averageGrade;
  final bool hasExcellenceDiscount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.userId,
    required this.programId,
    required this.duration,
    required this.classId,
    required this.status,
    required this.totalFees,
    required this.paidAmount,
    required this.discount,
    required this.enrollmentDate,
    this.completionDate,
    required this.attendancePercentage,
    required this.averageGrade,
    required this.hasExcellenceDiscount,
    required this.createdAt,
    required this.updatedAt,
  });

  double get remainingBalance => totalFees - paidAmount;
  bool get hasOutstandingBalance => remainingBalance > 0;

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'programId': programId,
    'duration': duration,
    'classId': classId,
    'status': status.name,
    'totalFees': totalFees,
    'paidAmount': paidAmount,
    'discount': discount,
    'enrollmentDate': enrollmentDate.toIso8601String(),
    'completionDate': completionDate?.toIso8601String(),
    'attendancePercentage': attendancePercentage,
    'averageGrade': averageGrade,
    'hasExcellenceDiscount': hasExcellenceDiscount,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Student.fromJson(Map<String, dynamic> json) => Student(
    id: json['id'] as String,
    userId: json['userId'] as String,
    programId: json['programId'] as String,
    duration: json['duration'] as int,
    classId: json['classId'] as String,
    status: StudentStatus.values.firstWhere((e) => e.name == json['status']),
    totalFees: (json['totalFees'] as num).toDouble(),
    paidAmount: (json['paidAmount'] as num).toDouble(),
    discount: (json['discount'] as num).toDouble(),
    enrollmentDate: DateTime.parse(json['enrollmentDate']),
    completionDate: json['completionDate'] != null ? DateTime.parse(json['completionDate']) : null,
    attendancePercentage: (json['attendancePercentage'] as num).toDouble(),
    averageGrade: (json['averageGrade'] as num).toDouble(),
    hasExcellenceDiscount: json['hasExcellenceDiscount'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Student copyWith({
    String? id,
    String? userId,
    String? programId,
    int? duration,
    String? classId,
    StudentStatus? status,
    double? totalFees,
    double? paidAmount,
    double? discount,
    DateTime? enrollmentDate,
    DateTime? completionDate,
    double? attendancePercentage,
    double? averageGrade,
    bool? hasExcellenceDiscount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Student(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    programId: programId ?? this.programId,
    duration: duration ?? this.duration,
    classId: classId ?? this.classId,
    status: status ?? this.status,
    totalFees: totalFees ?? this.totalFees,
    paidAmount: paidAmount ?? this.paidAmount,
    discount: discount ?? this.discount,
    enrollmentDate: enrollmentDate ?? this.enrollmentDate,
    completionDate: completionDate ?? this.completionDate,
    attendancePercentage: attendancePercentage ?? this.attendancePercentage,
    averageGrade: averageGrade ?? this.averageGrade,
    hasExcellenceDiscount: hasExcellenceDiscount ?? this.hasExcellenceDiscount,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
