import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/profile/data/profile_repository.dart';

void main() {
  test('normalise les formats usuels de numéros camerounais', () {
    expect(normalizeCameroonPhone('699 00 00 00'), '+237699000000');
    expect(normalizeCameroonPhone('237 699 00 00 00'), '+237699000000');
    expect(normalizeCameroonPhone('00237 699 00 00 00'), '+237699000000');
  });

  test('refuse un numéro non camerounais ou un nom trop court', () {
    expect(
      validateProfileFields(
        firstName: 'A',
        lastName: 'Nana',
        phoneNumber: '+237699000000',
      ),
      isNotNull,
    );
    expect(
      validateProfileFields(
        firstName: 'Awa',
        lastName: 'Nana',
        phoneNumber: '+33600000000',
      ),
      isNotNull,
    );
  });

  test('accepte les champs valides et un téléphone absent', () {
    expect(
      validateProfileFields(
        firstName: 'Awa',
        lastName: 'Nana',
        phoneNumber: '',
      ),
      isNull,
    );
  });
}
