class Department {
  final String id;
  final String name;
  final String description;
  final List<String> programIds;
  final List<String> teacherIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Department({
    required this.id,
    required this.name,
    required this.description,
    required this.programIds,
    required this.teacherIds,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'programIds': programIds,
    'teacherIds': teacherIds,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory Department.fromJson(Map<String, dynamic> json) => Department(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    programIds: List<String>.from(json['programIds'] ?? []),
    teacherIds: List<String>.from(json['teacherIds'] ?? []),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  Department copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? programIds,
    List<String>? teacherIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Department(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description ?? this.description,
    programIds: programIds ?? this.programIds,
    teacherIds: teacherIds ?? this.teacherIds,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
