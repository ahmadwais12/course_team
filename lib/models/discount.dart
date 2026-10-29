enum DiscountType { excellence, family, staff, promotional, special, percentage, fixed }

class Discount {
  final String id;
  final DiscountType type;
  final double percentage;
  final String? conditions;
  final DateTime? validUntil;
  final bool isActive;
  final DateTime createdAt;

  Discount({
    required this.id,
    required this.type,
    required this.percentage,
    this.conditions,
    this.validUntil,
    required this.isActive,
    required this.createdAt,
  });

  static DiscountType _parseType(dynamic raw) {
    final name = raw?.toString();
    if (name == null) return DiscountType.percentage;
    return DiscountType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => DiscountType.percentage,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': type.name,
        'type': type == DiscountType.fixed ? 'fixed' : 'percentage',
        'percentage': percentage,
        'value': percentage,
        'conditions': conditions,
        'valid_until': validUntil?.toIso8601String(),
        'active': isActive,
        'is_active': isActive,
        'created_at': createdAt.toIso8601String(),
      };

  factory Discount.fromJson(Map<String, dynamic> json) => Discount(
        id: json['id'] as String,
        type: _parseType(json['type']),
        percentage: ((json['percentage'] ?? json['value'] ?? 0) as num).toDouble(),
        conditions: (json['conditions'] ?? json['description']) as String?,
        validUntil: (json['valid_until'] ?? json['validUntil']) != null
            ? DateTime.parse((json['valid_until'] ?? json['validUntil']).toString())
            : null,
        isActive: (json['is_active'] ?? json['isActive'] ?? json['active'] ?? true) as bool,
        createdAt: DateTime.parse(
            (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String())
                .toString()),
      );

  Discount copyWith({
    String? id,
    DiscountType? type,
    double? percentage,
    String? conditions,
    DateTime? validUntil,
    bool? isActive,
    DateTime? createdAt,
  }) =>
      Discount(
        id: id ?? this.id,
        type: type ?? this.type,
        percentage: percentage ?? this.percentage,
        conditions: conditions ?? this.conditions,
        validUntil: validUntil ?? this.validUntil,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );
}
