import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:course_emis/models/book.dart';
import 'package:course_emis/repositories/book_repository.dart';

final bookRepositoryProvider = Provider((ref) => BookRepository());

final booksNotifierProvider = StateNotifierProvider<BooksNotifier, AsyncValue<List<Book>>>((ref) {
  return BooksNotifier(ref.read(bookRepositoryProvider));
});

class BooksNotifier extends StateNotifier<AsyncValue<List<Book>>> {
  final BookRepository _repository;
  
  BooksNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBooks();
  }
  
  Future<void> loadBooks() async {
    state = const AsyncValue.loading();
    try {
      final data = await _repository.getAll();
      state = AsyncValue.data(data);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBook(Book book) async {
    await _repository.create(book);
    await loadBooks();
  }

  Future<void> updateBook(Book book) async {
    await _repository.update(book);
    await loadBooks();
  }

  Future<void> deleteBook(String id) async {
    await _repository.delete(id);
    await loadBooks();
  }
}
