import 'dart:math';

/// Short, human-typeable restaurant join codes ("join a business without a
/// password"). Excludes visually-ambiguous characters (0/O, 1/I).
class JoinCode {
  static const _chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  static String generate({int length = 7}) {
    final rnd = Random.secure();
    return List.generate(length, (_) => _chars[rnd.nextInt(_chars.length)]).join();
  }
}
