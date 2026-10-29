import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/models/discount.dart';

class DiscountRepository {
  final SupabaseClient supabase = Supabase.instance.client;

  Future<List<Discount>> getAll() async {
    try {
      final response = await supabase
          .from('discounts')
          .select()
          .order('created_at', ascending: false);
      return (response as List)
          .map((e) => Discount.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch discounts: $e');
    }
  }

  Future<Discount?> getById(String id) async {
    try {
      final response = await supabase
          .from('discounts')
          .select()
          .eq('id', id)
          .single();
      return Discount.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      return null;
    }
  }

  Future<void> create(Discount discount) async {
    try {
      final data = discount.toJson();
      data['created_at'] = DateTime.now().toIso8601String();
      await supabase.from('discounts').insert(data);
    } catch (e) {
      throw Exception('Failed to create discount: $e');
    }
  }

  Future<void> update(Discount discount) async {
    try {
      final data = discount.toJson();
      data['updated_at'] = DateTime.now().toIso8601String();
      await supabase.from('discounts').update(data).eq('id', discount.id);
    } catch (e) {
      throw Exception('Failed to update discount: $e');
    }
  }

  Future<void> delete(String id) async {
    try {
      await supabase.from('discounts').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete discount: $e');
    }
  }

  Stream<List<Discount>> streamAll() {
    return supabase
        .from('discounts')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((data) =>
            data.map((json) => Discount.fromJson(json)).toList());
  }
}
