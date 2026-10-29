import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DriversRepository extends BaseRepository {
  DriversRepository() : super('drivers');

  Future<List<Map<String, dynamic>>> getAllDrivers({
    bool? available,
    String? vehicleType,
    int? minExperience,
  }) async {
    var query = Supabase.instance.client.from('drivers').select();

    if (available != null) {
      query = query.eq('available', available);
    }
    if (vehicleType != null) {
      query = query.eq('vehicle_type', vehicleType);
    }
    if (minExperience != null) {
      query = query.gte('experience_years', minExperience);
    }

    final response = await query.order('name');
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamDrivers({
    bool? available,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('drivers')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (available != null) {
        filtered = filtered.where((d) => d['available'] == available).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableDrivers() async {
    final response = await Supabase.instance.client
        .from('drivers')
        .select()
        .eq('available', true)
        .order('name');
    return response;
  }

  Future<void> assignRoute(String driverId, String routeId) async {
    await Supabase.instance.client.from('drivers').update({
      'current_route': routeId,
      'available': false,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', driverId);
  }

  Future<void> unassignRoute(String driverId) async {
    await Supabase.instance.client.from('drivers').update({
      'current_route': null,
      'available': true,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', driverId);
  }

  Future<void> updateAvailability(String driverId, bool available) async {
    await Supabase.instance.client.from('drivers').update({
      'available': available,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', driverId);
  }

  Future<List<String>> getDistinctVehicleTypes() async {
    final response = await Supabase.instance.client
        .from('drivers')
        .select('vehicle_type')
        .not('vehicle_type', 'is', null);

    final types = response
        .map((d) => d['vehicle_type'] as String?)
        .where((t) => t != null)
        .toSet()
        .toList();
    types.sort();
    return types.cast<String>();
  }

  Future<Map<String, dynamic>> getDriverStats() async {
    final response = await Supabase.instance.client.from('drivers').select('available, current_route');

    int total = response.length;
    int available = 0;
    int assigned = 0;
    int onDuty = 0;

    for (final driver in response) {
      final isAvailable = driver['available'] as bool? ?? false;
      final currentRoute = driver['current_route'] as String?;

      if (isAvailable) available++;
      if (currentRoute != null && currentRoute.isNotEmpty) {
        assigned++;
        onDuty++;
      }
    }

    return {
      'total': total,
      'available': available,
      'assigned': assigned,
      'onDuty': onDuty,
    };
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['available'] == null) {
      data['available'] = true;
    }
    if (data['experience_years'] == null) {
      data['experience_years'] = 0;
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
