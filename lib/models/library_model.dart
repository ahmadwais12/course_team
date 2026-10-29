import 'package:json_annotation/json_annotation.dart';

part 'library_model.g.dart';

@JsonSerializable()
class Book {
  final String id;
  final String title;
  final String author;
  final String isbn;
  final String category;
  final String publisher;
  @JsonKey(name: 'publication_year')
  final int publicationYear;
  @JsonKey(name: 'total_copies')
  final int totalCopies;
  @JsonKey(name: 'available_copies')
  final int availableCopies;
  @JsonKey(name: 'shelf_location')
  final String? shelfLocation;
  final String? description;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.isbn,
    required this.category,
    required this.publisher,
    this.publicationYear = 0,
    required this.totalCopies,
    this.availableCopies = 0,
    this.shelfLocation,
    this.description,
  });

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
  Map<String, dynamic> toJson() => _$BookToJson(this);
}

@JsonSerializable()
class BookLoan {
  final String id;
  @JsonKey(name: 'book_id')
  final String bookId;
  @JsonKey(name: 'borrower_id')
  final String borrowerId;
  @JsonKey(name: 'borrower_type')
  final String borrowerType;
  @JsonKey(name: 'issue_date')
  final DateTime issueDate;
  @JsonKey(name: 'due_date')
  final DateTime dueDate;
  @JsonKey(name: 'return_date')
  final DateTime? returnDate;
  final String status;
  @JsonKey(name: 'fine_amount')
  final double fineAmount;
  final String? notes;

  BookLoan({
    required this.id,
    required this.bookId,
    required this.borrowerId,
    required this.borrowerType,
    required this.issueDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    this.fineAmount = 0.0,
    this.notes,
  });

  factory BookLoan.fromJson(Map<String, dynamic> json) => _$BookLoanFromJson(json);
  Map<String, dynamic> toJson() => _$BookLoanToJson(this);
}

@JsonSerializable()
class LibraryMember {
  final String id;
  @JsonKey(name: 'member_id')
  final String memberId;
  @JsonKey(name: 'member_type')
  final String memberType;
  @JsonKey(name: 'join_date')
  final DateTime joinDate;
  final String status;
  @JsonKey(name: 'max_books_allowed')
  final int maxBooksAllowed;
  @JsonKey(name: 'current_borrowed')
  final int currentBorrowed;

  LibraryMember({
    required this.id,
    required this.memberId,
    required this.memberType,
    required this.joinDate,
    required this.status,
    this.maxBooksAllowed = 3,
    this.currentBorrowed = 0,
  });

  factory LibraryMember.fromJson(Map<String, dynamic> json) => _$LibraryMemberFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryMemberToJson(this);
}

@JsonSerializable()
class LibraryRecord {
  final List<Book> books;
  final List<BookLoan> loans;
  final List<LibraryMember> members;

  LibraryRecord({
    required this.books,
    required this.loans,
    required this.members,
  });

  factory LibraryRecord.fromJson(Map<String, dynamic> json) => _$LibraryRecordFromJson(json);
  Map<String, dynamic> toJson() => _$LibraryRecordToJson(this);
}
