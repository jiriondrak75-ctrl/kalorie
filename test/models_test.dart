import 'package:flutter_test/flutter_test.dart';
import 'package:kalorie/models.dart';

void main() {
  test('norm odstraní diakritiku', () {
    expect(norm(' Šťavnatý ŘÍZEK '), 'stavnaty rizek');
  });

  test('fmtNum používá čárku a ořízne nuly', () {
    expect(fmtNum(12.5), '12,5');
    expect(fmtNum(100), '100');
    expect(fmtNum(1234.4, decimals: 0), '1234');
  });

  test('parseNum přijme čárku i tečku', () {
    expect(parseNum('1,5'), 1.5);
    expect(parseNum('2.25'), 2.25);
    expect(parseNum('abc'), isNull);
  });

  test('Entry počítá kcal na 100 g i na porci', () {
    const g = Food(name: 'Rohlík', kcal: 290, protein: 9);
    expect(Entry(food: g, amount: 50).kcal, 145);
    expect(Entry(food: g, amount: 50).protein, 4.5);
    const s = Food(name: 'Oběd', kcal: 600, perServing: true);
    expect(Entry(food: s, amount: 2).kcal, 1200);
  });
}
