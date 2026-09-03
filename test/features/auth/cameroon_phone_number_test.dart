import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/auth/domain/cameroon_phone_number.dart';

void main() {
  group('CameroonPhoneNumber', () {
    test('normalizes supported local and international forms to E.164', () {
      expect(CameroonPhoneNumber.normalize('699 12 34 56'), '+237699123456');
      expect(CameroonPhoneNumber.normalize('237 699123456'), '+237699123456');
      expect(
        CameroonPhoneNumber.normalize('00237-699-123-456'),
        '+237699123456',
      );
      expect(
        CameroonPhoneNumber.normalize('+237 (699) 123 456'),
        '+237699123456',
      );
    });

    test('rejects non-mobile and malformed numbers', () {
      expect(
        () => CameroonPhoneNumber.normalize('222123456'),
        throwsA(isA<PhoneNumberFormatException>()),
      );
      expect(
        () => CameroonPhoneNumber.normalize('69912345'),
        throwsA(isA<PhoneNumberFormatException>()),
      );
    });
  });
}
