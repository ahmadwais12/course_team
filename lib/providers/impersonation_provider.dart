import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:course_emis/app_routes_all.dart';
import 'package:course_emis/services/impersonation_service.dart';
import 'package:course_emis/utils/app_logger.dart';

/// UI state reflecting an active impersonation (or none).
class ImpersonationUiState {
  final ImpersonationSession? session;
  final bool loading;

  const ImpersonationUiState({this.session, this.loading = false});

  bool get isImpersonating => session != null && session!.isActive;

  String get effectiveRole => session?.targetRole?.toLowerCase() ?? '';

  bool get isEmpty => session == null;

  ImpersonationUiState copyWith({ImpersonationSession? session, bool? loading}) {
    return ImpersonationUiState(
      session: session ?? this.session,
      loading: loading ?? this.loading,
    );
  }
}

class ImpersonationNotifier extends StateNotifier<ImpersonationUiState> {
  final ImpersonationService _service;

  ImpersonationNotifier(this._service) : super(const ImpersonationUiState());

  /// Called on app start / after login to restore a persisted session.
  Future<void> load() async {
    state = state.copyWith(loading: true);
    try {
      final session = await _service.getSession();
      if (session != null && session.isActive) {
        state = state.copyWith(session: session);
      } else if (session != null) {
        await _service.clearImpersonation();
        state = const ImpersonationUiState();
      } else {
        state = const ImpersonationUiState();
      }
    } catch (e) {
      AppLogger.w('Failed to load impersonation session: $e',
          tag: 'ImpersonationProvider');
      state = const ImpersonationUiState();
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<void> start({required String targetUserId, String? reason}) async {
    final session = await _service.startImpersonation(
      targetUserId: targetUserId,
      reason: reason,
    );
    state = state.copyWith(session: session);
  }

  Future<void> exit() async {
    await _service.exitImpersonation();
    state = const ImpersonationUiState();
  }
}

final impersonationProvider =
    StateNotifierProvider<ImpersonationNotifier, ImpersonationUiState>((ref) {
  final service = ref.watch(impersonationServiceProvider);
  return ImpersonationNotifier(service);
});

/// Resolve the role the app should behave as right now.
///
/// While an active impersonation exists we use the TARGET user's role, so all
/// panels/nav behave like the impersonated user. Otherwise fall back to the
/// authenticated user's role from auth metadata.
String resolveEffectiveRole(WidgetRef ref) {
  final imp = ref.read(impersonationProvider);
  if (imp.isImpersonating) return imp.effectiveRole;
  return Supabase.instance.client.auth.currentUser
          ?.userMetadata?['role']
          ?.toString()
          .toLowerCase() ??
      '';
}

/// Resolve the user id the app should behave as right now.
String? resolveEffectiveUserId(WidgetRef ref) {
  final imp = ref.read(impersonationProvider);
  if (imp.isImpersonating && imp.session != null) {
    return imp.session!.targetUserId;
  }
  return Supabase.instance.client.auth.currentUser?.id;
}

/// Home (panel) route for a role — mirrors splash_screen's switch.
String homeRouteForRole(String? role) {
  switch (role) {
    case 'super_admin':
      return AppRoutesAll.superAdmin;
    case 'admin':
      return AppRoutesAll.adminPanel;
    case 'teacher':
      return AppRoutesAll.teacherPanel;
    case 'staff':
      return AppRoutesAll.staffPanel;
    case 'academic_support':
      return AppRoutesAll.academicSupportPanel;
    case 'accountant':
      return AppRoutesAll.accountantPanel;
    case 'librarian':
      return AppRoutesAll.librarianPanel;
    case 'receptionist':
      return AppRoutesAll.receptionistPanel;
    case 'hr_manager':
      return AppRoutesAll.hrManagerPanel;
    case 'inventory_manager':
      return AppRoutesAll.inventoryManagerPanel;
    case 'it_support':
      return AppRoutesAll.itSupportPanel;
    case 'maintenance':
      return AppRoutesAll.maintenancePanel;
    case 'event_manager':
      return AppRoutesAll.eventManagerPanel;
    case 'complaint_manager':
      return AppRoutesAll.complaintManagerPanel;
    case 'staff_finance':
      return AppRoutesAll.financeAccountsPanel;
    case 'staff_academic':
      return AppRoutesAll.academicSupportPanel;
    case 'staff_hr':
      return AppRoutesAll.hrOperationsPanel;
    case 'staff_it':
      return AppRoutesAll.itSystemSupportPanel;
    case 'staff_comm':
      return AppRoutesAll.communicationEventsPanel;
    case 'guardian':
    case 'student':
    default:
      return AppRoutesAll.dashboard;
  }
}