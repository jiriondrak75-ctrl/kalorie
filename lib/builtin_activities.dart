import 'models.dart';

/// Běžné aktivity. Hodnoty MET jsou orientační podle
/// Compendium of Physical Activities (Ainsworth a kol.).
Activity _a(String name, double met) => Activity(name: name, met: met);

final builtinActivities = <Activity>[
  // Chůze
  _a('Chůze pomalá (3 km/h)', 2.8),
  _a('Chůze běžná (5 km/h)', 3.5),
  _a('Chůze svižná (6 km/h)', 4.3),
  _a('Venčení psa', 3.0),
  _a('Nordic walking', 4.8),
  _a('Turistika', 6.0),
  // Běh
  _a('Běh 8 km/h', 8.3),
  _a('Běh 10 km/h', 9.8),
  _a('Běh 12 km/h', 11.8),
  // Kolo
  _a('Kolo pohodově (do 16 km/h)', 4.0),
  _a('Kolo silnice 20–22 km/h', 8.0),
  _a('Kolo silnice 25+ km/h', 10.0),
  _a('Kolo gravel / MTB', 8.5),
  _a('Rotoped střední zátěž', 6.8),
  // Voda
  _a('Plavání pomalé', 5.8),
  _a('Plavání rychlé', 9.8),
  // Posilování a cvičení
  _a('Posilovna', 5.0),
  _a('Kruhový trénink / crossfit', 8.0),
  _a('Veslovací trenažér', 7.0),
  _a('Jóga', 2.5),
  _a('Strečink', 2.3),
  _a('Tanec', 5.0),
  // Sporty
  _a('Fotbal', 7.0),
  _a('Tenis', 7.3),
  _a('Badminton', 5.5),
  _a('Lyžování sjezd', 5.3),
  _a('Běžky', 9.0),
  // Doma a na zahradě
  _a('Práce na zahradě', 3.8),
  _a('Sekání trávy', 4.5),
  _a('Úklid domácnosti', 3.3),
];
