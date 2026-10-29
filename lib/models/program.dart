

// ignore_for_file: constant_identifier_names

enum ProgramType { CL, DEL, TOEFL, IELTS, PTE, SpokenEnglish, BusinessEnglish }

class Program {
  final String id;
  final String name;
  final String code;
  final ProgramType type;
  final String departmentId;
  final List<int> allowedDurations; // in months
  final Map<int, double> pricing; // duration -> price
  final String description;
  final bool isActive;
  final int enrolledStudents;
  final DateTime createdAt;
  final DateTime updatedAt;

  Program({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.departmentId,
    required this.allowedDurations,
    required this.pricing,
    required this.description,
    required this.isActive,
    required this.enrolledStudents,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'type': type.name,
    'departmentId': departmentId,
    'allowedDurations': allowedDurations,
    'pricing': pricing.map((k, v) => MapEntry(k.toString(), v)),
    'description': description,
    'isActive': isActive,
    'enrolledStudents': enrolledStudents,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Program.fromJson(Map<String, dynamic> json) => Program(
    id: json['id'] as String,
    name: json['name'] as String,
    code: json['code'] as String? ?? '',
    type: ProgramType.values.firstWhere((e) => e.name == json['type']),
    departmentId: json['departmentId'] as String,
    allowedDurations: List<int>.from(json['allowedDurations'] ?? []),
    pricing: (json['pricing'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(int.parse(k), (v as num).toDouble()),
    ),
    description: json['description'] as String,
    isActive: json['isActive'] as bool,
    enrolledStudents: json['enrolledStudents'] as int? ?? 0,
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Program copyWith({
    String? id,
    String? name,
    String? code,
    ProgramType? type,
    String? departmentId,
    List<int>? allowedDurations,
    Map<int, double>? pricing,
    String? description,
    bool? isActive,
    int? enrolledStudents,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Program(
    id: id ?? this.id,
    name: name ?? this.name,
    code: code ?? this.code,
    type: type ?? this.type,
    departmentId: departmentId ?? this.departmentId,
    allowedDurations: allowedDurations ?? this.allowedDurations,
    pricing: pricing ?? this.pricing,
    description: description ?? this.description,
    isActive: isActive ?? this.isActive,
    enrolledStudents: enrolledStudents ?? this.enrolledStudents,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
