import 'package:flutter_test/flutter_test.dart';
import 'package:serviceflow/features/auth/domain/entities/app_user.dart';

void main() {
  group('AppRole.tryParse', () {
    test('accepts the wire values', () {
      expect(AppRole.tryParse('ceo'), AppRole.ceo);
      expect(AppRole.tryParse('employee'), AppRole.employee);
    });

    test('tolerates casing and whitespace typed into the console', () {
      expect(AppRole.tryParse('  CEO '), AppRole.ceo);
      expect(AppRole.tryParse('Employee'), AppRole.employee);
    });

    test('aliases the legacy Senior Manager account to CEO', () {
      expect(AppRole.tryParse('Senior Manager'), AppRole.ceo);
    });

    test('rejects anything else', () {
      expect(AppRole.tryParse('manager'), isNull);
      expect(AppRole.tryParse(''), isNull);
      expect(AppRole.tryParse(null), isNull);
      expect(AppRole.tryParse(42), isNull);
    });
  });

  test('labels are what the user sees', () {
    expect(AppRole.ceo.label, 'CEO');
    expect(AppRole.employee.label, 'Employee');
  });
}
