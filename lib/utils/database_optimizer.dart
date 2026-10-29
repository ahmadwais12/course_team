import 'package:supabase_flutter/supabase_flutter.dart';

class DatabaseOptimizer {
  static final instance = DatabaseOptimizer._();
  DatabaseOptimizer._();

  final _supabase = Supabase.instance.client;
  final _cache = <String, CacheEntry>{};

  // Cached query with TTL
  Future<List<Map<String, dynamic>>> cachedQuery(
    String key,
    Future<List<Map<String, dynamic>>> Function() query, {
    Duration ttl = const Duration(minutes: 5),
  }) async {
    final cached = _cache[key];
    if (cached != null && !cached.isExpired) {
      return cached.data;
    }

    final data = await query();
    _cache[key] = CacheEntry(data, DateTime.now().add(ttl));
    return data;
  }

  // Batch operations
  Future<void> batchInsert(String table, List<Map<String, dynamic>> records) async {
    const batchSize = 100;
    for (var i = 0; i < records.length; i += batchSize) {
      final batch = records.skip(i).take(batchSize).toList();
      await _supabase.from(table).insert(batch);
    }
  }

  // Paginated query
  Future<Map<String, dynamic>> paginatedQuery(
    String table, {
    required int page,
    required int pageSize,
    String? orderBy,
    Map<String, dynamic>? filters,
  }) async {
    var query = _supabase.from(table).select('*');

    if (filters != null) {
      filters.forEach((key, value) {
        if (value != null) {
          query = query.eq(key, value);
        }
      });
    }

    final from = (page - 1) * pageSize;
    final to = from + pageSize - 1;
    
    if (orderBy != null) {
      final response = await query.order(orderBy).range(from, to);
      return {
        'data': response,
        'page': page,
        'pageSize': pageSize,
        'hasMore': response.length == pageSize,
      };
    }

    final response = await query.range(from, to);
    return {
      'data': response,
      'page': page,
      'pageSize': pageSize,
      'hasMore': response.length == pageSize,
    };
  }

  // Clear cache
  void clearCache([String? key]) {
    if (key != null) {
      _cache.remove(key);
    } else {
      _cache.clear();
    }
  }
}

class CacheEntry {
  final List<Map<String, dynamic>> data;
  final DateTime expiresAt;

  CacheEntry(this.data, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
