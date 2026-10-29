class Class {
  final String id;
  final String name;
  final String programId;
  final String teacherId;
  final int capacity;
  final int enrolledCount;
  final Map<String, String> schedule;
  final DateTime startDate;
  final DateTime endDate;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Class({
    required this.id,
    required this.name,
    required this.programId,
    required this.teacherId,
    required this.capacity,
    required this.enrolledCount,
    required this.schedule,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'programId': programId,
        'teacherId': teacherId,
        'capacity': capacity,
        'enrolledCount': enrolledCount,
        'schedule': schedule,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'status': status,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Class.fromJson(Map<String, dynamic> json) => Class(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        programId: json['programId'] as String,
        teacherId: json['teacherId'] as String,
        capacity: json['capacity'] as int,
        enrolledCount: json['enrolledCount'] as int? ?? 0,
        schedule: Map<String, String>.from(json['schedule'] ?? {}),
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        status: json['status'] as String,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  Class copyWith({
    String? id,
    String? name,
    String? programId,
    String? teacherId,
    int? capacity,
    int? enrolledCount,
    Map<String, String>? schedule,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      Class(
        id: id ?? this.id,
        name: name ?? this.name,
        programId: programId ?? this.programId,
        teacherId: teacherId ?? this.teacherId,
        capacity: capacity ?? this.capacity,
        enrolledCount: enrolledCount ?? this.enrolledCount,
        schedule: schedule ?? this.schedule,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        status: status ?? this.status,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
