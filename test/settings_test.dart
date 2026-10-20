import 'package:flutter_test/flutter_test.dart';
import 'package:kalorie/storage.dart';

void main() {
  test('BMR podle Mifflin-St Jeor', () {
    const m = Settings(weight: 80, height: 180, age: 30, male: true);
    expect(m.bmr, 1780);
    const f = Settings(weight: 60, height: 165, age: 30, male: false);
    expect(f.bmr, closeTo(1320.25, 0.001));
  });

  test('BMR bez kompletních údajů je null', () {
    expect(const Settings(weight: 80, height: 180, male: true).bmr, isNull);
  });
}
