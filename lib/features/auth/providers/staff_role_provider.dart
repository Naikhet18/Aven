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
///
/// `null` is treated as full access, not "most restricted": it means a
/// business_id was stored locally *before* roles existed (an install that
/// predates this feature), and the account that set it up was, by
/// definition, a full-access owner at the time. Treating it as STAFF-level
/// would both lock out a real existing owner and create an infinite
/// redirect loop (homeRouteForRole(null) points at '/', which this function
/// would then immediately deny for a null role, bouncing right back).
/// Every *new* login/join path always sets an explicit role, so `null`
/// should only ever occur on such a pre-existing install.
bool isRouteAllowedForRole(String? role, String location) {
  if (role == null || role.isOwner) return true;

  const managerOnlyDenied = {'/finance'};
  const staffAllowed = {'/new-order', '/kitchen', '/settings'};

  if (role.isManager) {
    return !managerOnlyDenied.any((p) => location.startsWith(p));
  }

  // STAFF: only the explicitly allowed set.
  return staffAllowed.any((p) => location.startsWith(p));
}
