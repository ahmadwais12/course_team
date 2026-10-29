import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:course_emis/config/all_page_definitions.dart';
import 'package:course_emis/config/panel_pages_config.dart';

/// Verifies that every More-menu page has a `route` that is actually
/// registered in the router built by `lib/nav.dart`.
///
/// go_router 17.x exposes no public route-matching API on [GoRouter]
/// (`match`/`findMatch` are internal), so we reconstruct the set of
/// registered paths from source instead:
///   - static paths: every `path:` literal or `path: AppRoutesAll.xxx`
///     in `lib/nav.dart` (resolved against `lib/app_routes_all.dart`)
///   - dynamic paths: `AllPageDefinitions.pages` → `.route`
/// A More page's route must be a member of that union.
void main() async {
  final navSource = File('lib/nav.dart').readAsStringSync();
  final routesSource = File('lib/app_routes_all.dart').readAsStringSync();

  final routeConstants = <String, String>{
    for (final m in RegExp(r"static const String (\w+) = '([^']*)';")
        .allMatches(routesSource))
      m.group(1)!: m.group(2)!,
  };

  final registered = <String>{
    // Static paths: string literals.
    for (final m in RegExp(r"path:\s*'([^']*)'").allMatches(navSource))
      m.group(1)!,
    // Static paths: AppRoutesAll.<name> identifiers, resolved to values.
    for (final m in RegExp(r'path:\s*AppRoutesAll\.(\w+)').allMatches(navSource))
      if (routeConstants.containsKey(m.group(1)))
        routeConstants[m.group(1)]!,
    // Dynamic paths: auto-generated routes from AllPageDefinitions.
    for (final def in AllPageDefinitions.pages) def.route,
  };

  const roles = [
    'super_admin', 'admin', 'teacher', 'academic_support', 'accountant',
    'librarian', 'receptionist', 'hr_manager', 'inventory_manager',
    'it_support', 'maintenance', 'event_manager', 'complaint_manager',
    'student', 'guardian', 'staff',
  ];

  String normalize(String p) => p.endsWith('/') ? p.substring(0, p.length - 1) : p;

  for (final role in roles) {
    test('$role: every More page route is registered', () {
      final pages = PanelPagesConfig.getPagesForPanel(role);
      expect(pages, isNotEmpty, reason: '$role has no More pages');
      for (final page in pages) {
        final route = page.route;
        expect(route, isNotNull,
            reason: '${page.id} ($role) has a null route — context.go(route) '
                'would throw, goNamed fallback needs a route name');
        expect(route!.contains(':'), isFalse,
            reason: '${page.id} ($role) route "$route" has path parameters — '
                'More pages must use plain paths');
        expect(registered.map(normalize), contains(normalize(route)),
            reason: '${page.id} ($role) route "$route" is not registered in '
                'nav.dart or AllPageDefinitions');
      }
    });
  }
}
