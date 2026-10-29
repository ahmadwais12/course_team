// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) => Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      isbn: json['isbn'] as String,
      category: json['category'] as String,
      publisher: json['publisher'] as String,
      publicationYear: (json['publication_year'] as num?)?.toInt() ?? 0,
      totalCopies: (json['total_copies'] as num).toInt(),
      availableCopies: (json['available_copies'] as num?)?.toInt() ?? 0,
      shelfLocation: json['shelf_location'] as String?,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'author': instance.author,
      'isbn': instance.isbn,
      'category': instance.category,
      'publisher': instance.publisher,
      'publication_year': instance.publicationYear,
      'total_copies': instance.totalCopies,
      'available_copies': instance.availableCopies,
      'shelf_location': instance.shelfLocation,
      'description': instance.description,
    };

BookLoan _$BookLoanFromJson(Map<String, dynamic> json) => BookLoan(
      id: json['id'] as String,
      bookId: json['book_id'] as String,
      borrowerId: json['borrower_id'] as String,
      borrowerType: json['borrower_type'] as String,
      issueDate: DateTime.parse(json['issue_date'] as String),
      dueDate: DateTime.parse(json['due_date'] as String),
      returnDate: json['return_date'] == null
          ? null
          : DateTime.parse(json['return_date'] as String),
      status: json['status'] as String,
      fineAmount: (json['fine_amount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$BookLoanToJson(BookLoan instance) => <String, dynamic>{
      'id': instance.id,
      'book_id': instance.bookId,
      'borrower_id': instance.borrowerId,
      'borrower_type': instance.borrowerType,
      'issue_date': instance.issueDate.toIso8601String(),
      'due_date': instance.dueDate.toIso8601String(),
      'return_date': instance.returnDate?.toIso8601String(),
      'status': instance.status,
      'fine_amount': instance.fineAmount,
      'notes': instance.notes,
    };

LibraryMember _$LibraryMemberFromJson(Map<String, dynamic> json) =>
    LibraryMember(
      id: json['id'] as String,
      memberId: json['member_id'] as String,
      memberType: json['member_type'] as String,
      joinDate: DateTime.parse(json['join_date'] as String),
      status: json['status'] as String,
      maxBooksAllowed: (json['max_books_allowed'] as num?)?.toInt() ?? 3,
      currentBorrowed: (json['current_borrowed'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LibraryMemberToJson(LibraryMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'member_id': instance.memberId,
      'member_type': instance.memberType,
      'join_date': instance.joinDate.toIso8601String(),
      'status': instance.status,
      'max_books_allowed': instance.maxBooksAllowed,
      'current_borrowed': instance.currentBorrowed,
    };

LibraryRecord _$LibraryRecordFromJson(Map<String, dynamic> json) =>
    LibraryRecord(
      books: (json['books'] as List<dynamic>)
          .map((e) => Book.fromJson(e as Map<String, dynamic>))
          .toList(),
      loans: (json['loans'] as List<dynamic>)
          .map((e) => BookLoan.fromJson(e as Map<String, dynamic>))
          .toList(),
      members: (json['members'] as List<dynamic>)
          .map((e) => LibraryMember.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LibraryRecordToJson(LibraryRecord instance) =>
    <String, dynamic>{
      'books': instance.books,
      'loans': instance.loans,
      'members': instance.members,
    };
