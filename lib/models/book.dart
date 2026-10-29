class Book {
  final String id;
  final String programId;
  final String title;
  final double price;
  final int stock;
  final String? isbn;
  final String description;
  final DateTime createdAt;

  Book({
    required this.id,
    required this.programId,
    required this.title,
    required this.price,
    required this.stock,
    this.isbn,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'program_id': programId.isEmpty ? null : programId,
        'title': title,
        'price': price,
        'selling_price': price,
        'stock': stock,
        'available_copies': stock,
        'isbn': isbn,
        'description': description,
        'created_at': createdAt.toIso8601String(),
      };

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as String,
        programId: (json['program_id'] ?? json['programId'] ?? '') as String,
        title: json['title'] as String? ?? '',
        price: ((json['price'] ?? json['selling_price'] ?? 0) as num).toDouble(),
        stock: ((json['stock'] ?? json['available_copies'] ?? 0) as num).toInt(),
        isbn: json['isbn'] as String?,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(
            (json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String())
                .toString()),
      );

  Book copyWith({
    String? id,
    String? programId,
    String? title,
    double? price,
    int? stock,
    String? isbn,
    String? description,
    DateTime? createdAt,
  }) =>
      Book(
        id: id ?? this.id,
        programId: programId ?? this.programId,
        title: title ?? this.title,
        price: price ?? this.price,
        stock: stock ?? this.stock,
        isbn: isbn ?? this.isbn,
        description: description ?? this.description,
        createdAt: createdAt ?? this.createdAt,
      );
}
