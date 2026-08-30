import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khao_piyo_pos/shared/providers/global_providers.dart';

/// OWNER, MANAGER, or STAFF -- the current device's role within the current
/// business, mirroring `business_members.role`. Persisted locally
/// (alongside business_id) so it's known instantly at boot, without an
/// extra round-trip, and works offline.
final currentStaffRoleProvider = StateProvider<String?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getString('staff_role');
});

extension StaffRoleChecks on String? {
  bool get isOwner => this == 'OWNER';
  bool get isManager => this == 'MANAGER';
  bool get isStaff => this == 'STAFF';
}

/// The route a role should land on right after boot/login.
String homeRouteForRole(String? role) => role.isStaff ? '/new-order' : '/';

/// Mirrors AppScaffold's per-destination role gating so a route hidden from
/// the nav can't still be reached via a deep link or the back button.
/// `null`/unrecognized roles are treated as fully restricted (STAFF-level)
/// rather than fully open, so a role that failed to load defaults to the
/// safer, more restrictive option.
bool isRouteAllowedForRole(String? role, String location) {
  if (role.isOwner) return true;

  const managerOnlyDenied = {'/finance'};
  const staffAllowed = {'/new-order', '/kitchen', '/settings'};

  if (role.isManager) {
    return !managerOnlyDenied.any((p) => location.startsWith(p));
  }

  // STAFF (or an unrecognized/missing role): only the explicitly allowed set.
  return staffAllowed.any((p) => location.startsWith(p));
}
