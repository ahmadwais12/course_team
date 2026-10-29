import 'package:course_emis/utils/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Tenant {
  final String id, name, slug, organizationType, plan, status;
  final String? tenantCode,
      parentTenantId,
      parentName,
      description,
      logoUrl,
      website,
      location,
      phone,
      email,
      ownerEmail,
      contactPhone;
  final int maxUsers, maxStorageMB;
  final Map<String, dynamic>? settings, workingHours;
  final bool featured, isActive;
  final double? latitude, longitude;
  final List<String> services;
  final DateTime createdAt;
  final DateTime? expiryDate;
  final int? activeUsersCount, totalStudentsCount, totalBranchesCount;

  Tenant(
      {required this.id,
      required this.name,
      required this.slug,
      required this.createdAt,
      this.tenantCode,
      this.parentTenantId,
      this.parentName,
      this.organizationType = 'branch',
      this.description,
      this.logoUrl,
      this.website,
      this.location,
      this.phone,
      this.email,
      this.plan = 'standard',
      this.status = 'active',
      this.maxUsers = 100,
      this.maxStorageMB = 1024,
      this.settings,
      this.featured = false,
      this.latitude,
      this.longitude,
      this.services = const [],
      this.workingHours,
      this.expiryDate,
      this.ownerEmail,
      this.contactPhone,
      this.isActive = true,
      this.activeUsersCount,
      this.totalStudentsCount,
      this.totalBranchesCount});

  bool get isCentral => organizationType == 'central';
  bool get isBranch => organizationType == 'branch';
  bool get hasParent => parentTenantId != null;
}

class TenantNotifier extends StateNotifier<List<Tenant>> {
  TenantNotifier() : super(const []) {
    loadTenants();
  }

  final _supabase = Supabase.instance.client;

  Future<void> loadTenants() async {
    try {
      final rows = List<Map<String, dynamic>>.from(
          await _supabase.from('tenants').select().order('created_at'));
      final namesById = {
        for (final row in rows) row['id'] as String: row['name'] as String
      };
      state = rows.map((row) => _fromRow(row, namesById)).toList();
    } catch (error, stackTrace) {
      AppLogger.e('Unable to load tenants.',
          error: error, stackTrace: stackTrace, tag: 'TenantProvider');
      rethrow;
    }
  }

  Tenant _fromRow(Map<String, dynamic> row, Map<String, String> namesById) {
    final parentId = row['parent_tenant_id'] as String?;
    return Tenant(
      id: row['id'] as String,
      name: row['name'] as String,
      slug: row['slug'] as String,
      tenantCode: row['tenant_code'] as String?,
      parentTenantId: parentId,
      parentName: parentId == null ? null : namesById[parentId],
      organizationType: (row['organization_type'] as String?) ?? 'branch',
      description: row['description'] as String?,
      logoUrl: row['logo_url'] as String?,
      website: row['website'] as String?,
      location: row['address'] as String?,
      phone: row['phone'] as String?,
      email: row['email'] as String?,
      plan: (row['plan'] as String?) ?? 'standard',
      maxUsers: (row['max_users'] as num?)?.toInt() ?? 100,
      maxStorageMB: (row['max_storage_mb'] as num?)?.toInt() ?? 1024,
      settings: row['settings'] == null
          ? null
          : Map<String, dynamic>.from(row['settings'] as Map),
      featured: (row['featured'] as bool?) ?? false,
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      services: List<String>.from((row['services'] as List?) ?? const []),
      workingHours: row['working_hours'] == null
          ? null
          : Map<String, dynamic>.from(row['working_hours'] as Map),
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.now(),
      isActive: (row['is_active'] as bool?) ?? true,
    );
  }

  Map<String, dynamic> _payload(Tenant tenant,
          {required bool includeTenantCode}) =>
      {
        'name': tenant.name,
        'slug': tenant.slug,
        if (includeTenantCode && tenant.tenantCode != null)
          'tenant_code': tenant.tenantCode,
        'organization_type': tenant.organizationType,
        'parent_tenant_id': tenant.parentTenantId,
        'description': tenant.description,
        'logo_url': tenant.logoUrl,
        'website': tenant.website,
        'address': tenant.location,
        'phone': tenant.phone,
        'email': tenant.email,
        'plan': tenant.plan.toLowerCase(),
        'max_users': tenant.maxUsers,
        'max_storage_mb': tenant.maxStorageMB,
        'featured': tenant.featured,
        'latitude': tenant.latitude,
        'longitude': tenant.longitude,
        'services': tenant.services,
        'working_hours': tenant.workingHours,
        'is_active': tenant.isActive,
      };

  List<Tenant> getCentralOrganizations() =>
      state.where((tenant) => tenant.isCentral).toList();
  List<Tenant> getAllBranches() =>
      state.where((tenant) => tenant.isBranch).toList();
  List<Tenant> getBranchesForCentral(String centralId) => state
      .where((tenant) => tenant.isBranch && tenant.parentTenantId == centralId)
      .toList();
  Tenant? getCentralForBranch(String branchId) {
    final branch = state.where((tenant) => tenant.id == branchId).firstOrNull;
    if (branch?.parentTenantId == null) return null;
    return state
        .where((tenant) => tenant.id == branch!.parentTenantId)
        .firstOrNull;
  }

  Future<void> addTenant(Tenant tenant) async {
    try {
      await _supabase
          .from('tenants')
          .insert(_payload(tenant, includeTenantCode: true));
      await loadTenants();
    } catch (error, stackTrace) {
      AppLogger.e('Unable to create tenant.',
          error: error, stackTrace: stackTrace, tag: 'TenantProvider');
      rethrow;
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _supabase
          .from('tenants')
          .update(_payload(tenant, includeTenantCode: true))
          .eq('id', tenant.id);
      await loadTenants();
    } catch (error, stackTrace) {
      AppLogger.e('Unable to update tenant.',
          error: error, stackTrace: stackTrace, tag: 'TenantProvider');
      rethrow;
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      // Branches reference this tenant via parent_tenant_id (self-FK without
      // CASCADE) — unlink them first so deleting a central org succeeds.
      await _supabase
          .from('tenants')
          .update({'parent_tenant_id': null})
          .eq('parent_tenant_id', id);
      await _supabase.from('tenants').delete().eq('id', id);
      await loadTenants();
    } catch (error, stackTrace) {
      AppLogger.e('Unable to delete tenant.',
          error: error, stackTrace: stackTrace, tag: 'TenantProvider');
      rethrow;
    }
  }
}

final tenantProvider = StateNotifierProvider<TenantNotifier, List<Tenant>>(
    (ref) => TenantNotifier());
final currentTenantProvider = StateProvider<Tenant?>((ref) {
  final tenants = ref.watch(tenantProvider);
  return tenants.isNotEmpty ? tenants.first : null;
});
