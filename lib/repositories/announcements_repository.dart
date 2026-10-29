import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AnnouncementsRepository extends BaseRepository {
  AnnouncementsRepository() : super('announcements');

  Future<List<Map<String, dynamic>>> getAllAnnouncements({
    String? status,
    String? audience,
    String? priority,
    bool? isPinned,
  }) async {
    var query = Supabase.instance.client.from('announcements').select();

    if (status != null) {
      query = query.eq('status', status);
    }
    if (audience != null) {
      query = query.eq('audience', audience);
    }
    if (priority != null) {
      query = query.eq('priority', priority);
    }
    if (isPinned != null) {
      query = query.eq('is_pinned', isPinned);
    }

    final response = await query.order('is_pinned', ascending: false)
        .order('created_at', ascending: false);
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamAnnouncements({
    String? status,
    String? audience,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('announcements')
        .stream(primaryKey: ['id'])) {
      // Filter in memory
      var filtered = data;
      if (status != null) {
        filtered = filtered.where((a) => a['status'] == status).toList();
      }
      if (audience != null) {
        filtered = filtered.where((a) => a['audience'] == audience).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveAnnouncements() async {
    final now = DateTime.now().toIso8601String();
    final response = await Supabase.instance.client
        .from('announcements')
        .select()
        .eq('status', 'published')
        .or('start_date.is.null,start_date.lte.$now')
        .or('end_date.is.null,end_date.gte.$now')
        .order('is_pinned', ascending: false)
        .order('created_at', ascending: false);
    return response;
  }

  Future<void> publishAnnouncement(String announcementId) async {
    await Supabase.instance.client.from('announcements').update({
      'status': 'published',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', announcementId);
  }

  Future<void> scheduleAnnouncement(
    String announcementId,
    DateTime startDate,
    DateTime? endDate,
  ) async {
    await Supabase.instance.client.from('announcements').update({
      'status': 'scheduled',
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', announcementId);
  }

  Future<void> archiveAnnouncement(String announcementId) async {
    await Supabase.instance.client.from('announcements').update({
      'status': 'archived',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', announcementId);
  }

  Future<void> incrementViews(String announcementId) async {
    await Supabase.instance.client.rpc('increment_announcement_views', params: {
      'announcement_id': announcementId,
    });
  }

  Future<void> pinAnnouncement(String announcementId, bool isPinned) async {
    await Supabase.instance.client.from('announcements').update({
      'is_pinned': isPinned,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', announcementId);
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    data['views'] = 0;
    if (data['status'] == null) {
      data['status'] = 'draft';
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
