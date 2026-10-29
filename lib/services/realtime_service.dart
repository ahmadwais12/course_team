import 'package:supabase_flutter/supabase_flutter.dart';

class RealtimeService {
  static final supabase = Supabase.instance.client;

  static RealtimeChannel subscribeToTable({
    required String table,
    required Function(Map<String, dynamic>) onInsert,
    required Function(Map<String, dynamic>) onUpdate,
    required Function(Map<String, dynamic>) onDelete,
  }) {
    return supabase.channel('public:$table').onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: table,
      callback: (payload) {
        if (payload.eventType == PostgresChangeEvent.insert) {
          onInsert(payload.newRecord);
        } else if (payload.eventType == PostgresChangeEvent.update) {
          onUpdate(payload.newRecord);
        } else if (payload.eventType == PostgresChangeEvent.delete) {
          onDelete(payload.oldRecord);
        }
      },
    ).subscribe();
  }

  static void unsubscribe(RealtimeChannel channel) {
    supabase.removeChannel(channel);
  }
}
