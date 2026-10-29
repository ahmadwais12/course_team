import 'package:supabase_flutter/supabase_flutter.dart';

/// Base repository with common CRUD operations and real-time stream support
abstract class BaseRepository<T> {
  final String tableName;
  final SupabaseClient client = Supabase.instance.client;
  final Map<String, RealtimeChannel> _channels = {};

  BaseRepository(this.tableName);

  // Get all records with optional filters
  Future<List<Map<String, dynamic>>> getAll({
    Map<String, dynamic>? filters,
    String? orderBy,
    bool ascending = false,
  }) async {
    final query = client.from(tableName).select();

    if (filters != null) {
      for (var entry in filters.entries) {
        query.eq(entry.key, entry.value);
      }
    }

    if (orderBy != null) {
      query.order(orderBy, ascending: ascending);
    } else {
      query.order('created_at', ascending: ascending);
    }

    final response = await query;
    return response
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList();
  }

  // Get single record by ID
  Future<Map<String, dynamic>?> getById(String id) async {
    final result = await client.from(tableName).select().eq('id', id).single();
    return Map<String, dynamic>.from(result);
  }

  // Create new record
  Future<void> create(Map<String, dynamic> data) async {
    await client.from(tableName).insert(data);
  }

  // Update existing record
  Future<void> update(String id, Map<String, dynamic> data) async {
    await client.from(tableName).update(data).eq('id', id);
  }

  // Delete record
  Future<void> delete(String id) async {
    await client.from(tableName).delete().eq('id', id);
  }

  // Real-time stream for changes using StreamController
  Stream<List<Map<String, dynamic>>> stream(
      {Map<String, dynamic>? filters}) async* {
    // Initial fetch
    yield await getAll(filters: filters);

    // Set up real-time subscription
    final channelName = 'public:$tableName:stream';
    final channel = client.channel(channelName);
    _channels[channelName] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {},
        )
        .subscribe();

    // Poll for changes every 2 seconds as fallback
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield await getAll(filters: filters);
    }
  }

  // Subscribe to real-time changes with callback
  void subscribe(Function(List<Map<String, dynamic>>) onData) {
    final channelName = '$tableName:realtime';
    final channel = client.channel(channelName);
    _channels[channelName] = channel;

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: tableName,
          callback: (payload) {
            getAll().then(onData);
          },
        )
        .subscribe();
  }

  // Unsubscribe from real-time changes
  void unsubscribe() {
    for (final entry in _channels.entries.toList()) {
      if (entry.key.contains(tableName)) {
        client.removeChannel(entry.value);
        _channels.remove(entry.key);
      }
    }
  }
}
