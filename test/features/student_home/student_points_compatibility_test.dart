import 'package:flutter_test/flutter_test.dart';
import 'package:intellia237/features/student_home/data/student_home_repository.dart';

void main() {
  test('lit points avant la clé legacy xp', () {
    expect(studentPointsFromProfile({'points': 120, 'xp': 90}), 120);
    expect(
      studentPointsFromProfile({
        'progress': {'points': 150, 'xp': 80},
        'points': 120,
      }),
      150,
    );
  });

  test('préserve les anciens profils qui ne contiennent que xp', () {
    expect(studentPointsFromProfile({'xp': 90}), 90);
    expect(
      studentPointsFromProfile({
        'progress': {'xp': 75},
      }),
      75,
    );
  });
}
