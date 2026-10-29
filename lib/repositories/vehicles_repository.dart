import 'package:course_emis/repositories/base_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehiclesRepository extends BaseRepository {
  VehiclesRepository() : super('vehicles');

  Future<List<Map<String, dynamic>>> getAllVehicles({
    String? status,
    String? type,
    bool? active,
    String? allocationStatus,
  }) async {
    var query = Supabase.instance.client.from('vehicles').select();

    if (status != null) {
      query = query.eq('status', status);
    }
    if (type != null) {
      query = query.eq('type', type);
    }
    if (active != null) {
      query = query.eq('active', active);
    }
    if (allocationStatus != null) {
      query = query.eq('allocation_status', allocationStatus);
    }

    final response = await query.order('vehicle_number');
    return response;
  }

  Stream<List<Map<String, dynamic>>> streamVehicles({
    String? status,
    String? allocationStatus,
  }) async* {
    await for (final data in Supabase.instance.client
        .from('vehicles')
        .stream(primaryKey: ['id'])) {
      var filtered = data;
      if (status != null) {
        filtered = filtered.where((v) => v['status'] == status).toList();
      }
      if (allocationStatus != null) {
        filtered = filtered.where((v) => v['allocation_status'] == allocationStatus).toList();
      }
      yield filtered;
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableVehicles() async {
    final response = await Supabase.instance.client
        .from('vehicles')
        .select()
        .eq('active', true)
        .eq('allocation_status', 'Available')
        .order('vehicle_number');
    return response;
  }

  Future<List<Map<String, dynamic>>> getVehiclesNeedingMaintenance() async {
    final response = await Supabase.instance.client
        .from('vehicles')
        .select()
        .eq('status', 'Maintenance')
        .or('next_service.lte.${DateTime.now().toIso8601String()},maintenance_status.eq.Needs Service')
        .order('next_service');
    return response;
  }

  Future<void> allocateVehicle(
    String vehicleId, {
    String? routeId,
    String? driverId,
  }) async {
    await Supabase.instance.client.from('vehicles').update({
      'allocated_route': routeId,
      'allocated_driver': driverId,
      'allocation_status': routeId != null || driverId != null ? 'Allocated' : 'Available',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', vehicleId);
  }

  Future<void> updateFuelLevel(String vehicleId, int fuelLevel) async {
    await Supabase.instance.client.from('vehicles').update({
      'fuel_level': fuelLevel,
      'last_refuel': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', vehicleId);
  }

  Future<void> recordTrip(
    String vehicleId, {
    required double distance,
    required double fuelConsumed,
  }) async {
    final vehicle = await getById(vehicleId);
    if (vehicle != null) {
      final currentTrips = (vehicle['total_trips'] as num?)?.toInt() ?? 0;
      final currentDistance = (vehicle['total_distance'] as num?)?.toDouble() ?? 0;
      final currentFuel = (vehicle['fuel_consumed'] as num?)?.toDouble() ?? 0;

      await Supabase.instance.client.from('vehicles').update({
        'total_trips': currentTrips + 1,
        'total_distance': currentDistance + distance,
        'fuel_consumed': currentFuel + fuelConsumed,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', vehicleId);
    }
  }

  Future<void> scheduleMaintenance(
    String vehicleId, {
    required DateTime nextService,
    String? maintenanceStatus,
  }) async {
    await Supabase.instance.client.from('vehicles').update({
      'next_service': nextService.toIso8601String(),
      'maintenance_status': maintenanceStatus ?? 'Scheduled',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', vehicleId);
  }

  Future<Map<String, dynamic>> getVehicleStats() async {
    final response = await Supabase.instance.client.from('vehicles').select('status, allocation_status, active');

    int total = response.length;
    int active = 0;
    int maintenance = 0;
    int inactive = 0;
    int available = 0;
    int allocated = 0;

    for (final vehicle in response) {
      final status = vehicle['status'] as String?;
      final allocStatus = vehicle['allocation_status'] as String?;
      final isActive = vehicle['active'] as bool? ?? false;

      if (isActive) active++;
      if (status == 'Maintenance') maintenance++;
      if (status == 'Inactive') inactive++;
      if (allocStatus == 'Available') available++;
      if (allocStatus == 'Allocated') allocated++;
    }

    return {
      'total': total,
      'active': active,
      'maintenance': maintenance,
      'inactive': inactive,
      'available': available,
      'allocated': allocated,
    };
  }

  @override
  Future<void> create(Map<String, dynamic> data) async {
    data['created_at'] = DateTime.now().toIso8601String();
    data['updated_at'] = DateTime.now().toIso8601String();
    if (data['allocation_status'] == null) {
      data['allocation_status'] = 'Available';
    }
    await super.create(data);
  }

  @override
  Future<void> update(String id, Map<String, dynamic> data) async {
    data['updated_at'] = DateTime.now().toIso8601String();
    await super.update(id, data);
  }
}
