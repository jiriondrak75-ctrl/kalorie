import 'models.dart';

/// Obecné potraviny s orientačními hodnotami na 100 g
/// (kcal, bílkoviny, sacharidy, tuky). Pro věci, které v OFF chybí.
Food _f(String name, double kcal, double p, double c, double f) =>
    Food(name: name, kcal: kcal, protein: p, carbs: c, fat: f);

final builtinFoods = <Food>[
  // Pečivo a přílohy
  _f('Rohlík', 290, 9, 57, 3),
  _f('Chléb kmínový', 240, 8, 48, 1.5),
  _f('Chléb celozrnný', 230, 9, 41, 3),
  _f('Houska', 280, 9, 56, 2.5),
  _f('Toustový chléb', 265, 8, 49, 4),
  _f('Rýže vařená', 130, 2.7, 28, 0.3),
  _f('Těstoviny vařené', 150, 5.5, 30, 0.9),
  _f('Brambory vařené', 80, 2, 17, 0.1),
  _f('Bramborová kaše', 95, 2, 14, 3.5),
  _f('Hranolky', 310, 3.5, 41, 15),
  _f('Knedlík houskový', 210, 6, 42, 1.5),
  _f('Ovesné vločky', 370, 13, 60, 7),
  // Mléčné a vejce
  _f('Vejce', 140, 12.5, 0.7, 9.5),
  _f('Mléko polotučné', 47, 3.3, 4.8, 1.5),
  _f('Jogurt bílý', 65, 4.5, 5, 3),
  _f('Řecký jogurt', 120, 6, 4, 10),
  _f('Tvaroh polotučný', 115, 13, 3.5, 5),
  _f('Eidam 30 %', 260, 29, 0.5, 16),
  _f('Máslo', 740, 0.7, 0.6, 82),
  _f('Smetana do kávy', 120, 3, 4, 10),
  // Maso a ryby
  _f('Kuřecí prsa', 110, 23, 0, 1.5),
  _f('Šunka', 110, 18, 1.5, 3.5),
  _f('Vepřové maso libové', 145, 21, 0, 6.5),
  _f('Hovězí maso libové', 150, 22, 0, 7),
  _f('Párek', 270, 12, 1.5, 24),
  _f('Salám', 390, 15, 1, 36),
  _f('Losos', 205, 20, 0, 13),
  _f('Tuňák ve vlastní šťávě', 115, 26, 0, 1),
  // Ovoce a zelenina
  _f('Jablko', 52, 0.3, 12, 0.2),
  _f('Banán', 90, 1.1, 21, 0.3),
  _f('Pomeranč', 47, 0.9, 10, 0.1),
  _f('Jahody', 33, 0.7, 6, 0.3),
  _f('Hroznové víno', 70, 0.7, 16, 0.2),
  _f('Rajče', 18, 0.9, 3, 0.2),
  _f('Okurka', 15, 0.7, 2.5, 0.1),
  _f('Paprika', 30, 1, 5, 0.3),
  _f('Mrkev', 40, 0.9, 8, 0.2),
  _f('Avokádo', 160, 2, 2, 15),
  // Ostatní
  _f('Ořechy vlašské', 650, 15, 7, 65),
  _f('Arašídové máslo', 600, 25, 15, 50),
  _f('Hořká čokoláda', 550, 7, 40, 38),
  _f('Mléčná čokoláda', 540, 7, 57, 31),
  _f('Med', 305, 0.3, 82, 0),
  _f('Cukr', 400, 0, 100, 0),
  _f('Olivový olej', 880, 0, 0, 100),
  _f('Pizza', 250, 10, 30, 10),
  // Nápoje (na 100 ml)
  _f('Pivo 10°', 35, 0.4, 2.8, 0),
  _f('Pivo 12°', 45, 0.5, 3.5, 0),
  _f('Víno bílé', 80, 0.1, 2.5, 0),
  _f('Víno červené', 85, 0.1, 2.5, 0),
  _f('Coca-Cola', 42, 0, 10.6, 0),
  _f('Pomerančový džus', 45, 0.7, 10, 0.2),
  _f('Káva s mlékem', 35, 1.8, 2.8, 1.8),
];
