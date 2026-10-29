import 'package:flutter_test/flutter_test.dart';
import 'package:course_emis/config/panel_pages_config.dart';

void main() {
  const roles = [
    'super_admin', 'admin', 'teacher', 'academic_support', 'accountant',
    'librarian', 'receptionist', 'hr_manager', 'inventory_manager',
    'it_support', 'maintenance', 'event_manager', 'complaint_manager',
    'student', 'guardian', 'staff',
  ];

  for (final role in roles) {
    test('$role: no duplicate page ids or names', () {
      final pages = PanelPagesConfig.getPagesForPanel(role);
      final ids = <String>{};
      final names = <String>{};
      for (final p in pages) {
        expect(ids.add(p.id), isTrue, reason: 'duplicate id ${p.id} in $role');
        final key = p.name.trim().toLowerCase();
        expect(names.add(key), isTrue,
            reason: 'duplicate name "${p.name}" (id ${p.id}) in $role');
      }
    });
  }

  test('known exact-name duplicates are resolved', () {
    final saNames = PanelPagesConfig.getPagesForPanel('super_admin')
        .map((p) => p.name.trim().toLowerCase());
    expect(saNames.where((n) => n == 'system settings').length, 0,
        reason: 'System Settings was merged into the Settings page');

    final adminNames = PanelPagesConfig.getPagesForPanel('admin')
        .map((p) => p.name.trim().toLowerCase());
    expect(adminNames.where((n) => n == 'announcements').length, 1);

    final teacherNames = PanelPagesConfig.getPagesForPanel('teacher')
        .map((p) => p.name.trim().toLowerCase());
    expect(teacherNames.where((n) => n == 'student groups').length, 1);

    final maintenanceNames = PanelPagesConfig.getPagesForPanel('maintenance')
        .map((p) => p.name.trim().toLowerCase());
    expect(maintenanceNames.where((n) => n == 'work orders').length, 1);
  });
}
