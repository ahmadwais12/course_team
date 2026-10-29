import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/book.dart';

class BookRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Book>> getAll() async {
    try {
      final response = await supabase
          .from('books')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Book.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch books: $e');
    }
  }

  Future<Book?> getById(String id) async {
    try {
      final response = await supabase
          .from('books')
          .select()
          .eq('id', id)
          .single();
      return Book.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<void> create(Book book) async {
    try {
      await supabase.from('books').insert(book.toJson());
    } catch (e) {
      throw Exception('Failed to create book: $e');
    }
  }

  Future<void> update(Book book) async {
    try {
      await supabase.from('books').update(book.toJson()).eq('id', book.id);
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('books').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  Stream<List<Book>> streamAll() {
    return supabase
        .from('books')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => Book.fromJson(json)).toList());
  }
}
