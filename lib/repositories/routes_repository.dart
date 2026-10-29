import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RoutesRepository extends BaseRepository {
  RoutesRepository() : super('routes');

  Future<List<Map<String, dynamic>>> getAllRoutes({
    String? status,
    String? assignedDriver,
    String? assignedVehicle,
  }) async {
    var query = Supabase.instance.client.from('routes').select();

    if (status != null) {
      query = query.eq('status', status);
    }
    if (assignedDriver != null) {
      query = query.eq('assigned_driver', assignedDriver);
    }
    if (assignedVehicle != null) {
      query = query.eq('assigned_vehicle', assignedVehicle);
    }

    final response = await query.order('name');
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamRoutes({
    String? status,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('routes')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (status != null) {
        filtered = filtered.where((r) => r['status'] == status).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getActiveRoutes() async {
    final response = await Supabase.instance.client
        .from('routes')
        .select()
        .eq('status', 'Active')
        .order('name');
    return response;
  }

  Future<void> assignDriver(String routeId, String driverId) async {
    await Supabase.instance.client.from('routes').update({
      'assigned_driver': driverId,
      'status': 'Active',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', routeId);
  }

  Future<void> assignVehicle(String routeId, String vehicleId) async {
    await Supabase.instance.client.from('routes').update({
      'assigned_vehicle': vehicleId,
      'vehicle_id': vehicleId,
      'status': 'Active',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', routeId);
  }

  Future<void> completeRoute(String routeId) async {
    await Supabase.instance.client.from('routes').update({
      'status': 'Completed',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', routeId);
  }

  Future<void> activateRoute(String routeId) async {
    await Supabase.instance.client.from('routes').update({
      'status': 'Active',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', routeId);
  }

  Future<List<Map<String, dynamic>>> getRoutesByVehicle(String vehicleId) async {
    final response = await Supabase.instance.client
        .from('routes')
        .select()
        .eq('vehicle_id', vehicleId)
        .order('created_at', ascending: false);
    return response;
  }

  Future<List<Map<String, dynamic>>> getRoutesByDriver(String driverId) async {
    final response = await Supabase.instance.client
        .from('routes')
        .select()
        .eq('assigned_driver', driverId)
        .order('created_at', ascending: false);
    return response;
  }

  Future<Map<String, dynamic>> getRouteStats() async {
    final response = await Supabase.instance.client.from('routes').select('status');

    int total = response.length;
    int active = 0;
    int pending = 0;
    int completed = 0;

    for (final route in response) {
      final status = route['status'] as String?;

      if (status == 'Active') active++;
      if (status == 'Pending') pending++;
      if (status == 'Completed') completed++;
    }

    return {
      'total': total,
      'active': active,
      'pending': pending,
      'completed': completed,
    };
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['status'] == null) {
      data['status'] = 'Pending';
    }
    if (data['stops'] == null) {
      data['stops'] = 0;
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
