import 'package:flutter_test/flutter_test.dart';
import 'package:khao_piyo_pos/core/utils/join_code.dart';

void main() {
  group('JoinCode', () {
    test('generates a 7-character code by default', () {
      expect(JoinCode.generate().length, 7);
    });

    test('excludes visually-ambiguous characters (0/O, 1/I)', () {
      final code = JoinCode.generate(length: 500);
      expect(code.contains('0'), isFalse);
      expect(code.contains('O'), isFalse);
      expect(code.contains('1'), isFalse);
      expect(code.contains('I'), isFalse);
    });

    test('is not the same every time', () {
      final codes = List.generate(20, (_) => JoinCode.generate()).toSet();
      expect(codes.length, greaterThan(1));
    });
  });
}
