# Kalorie

Jednoduchá osobní aplikace pro Android na zapisování snědeného jídla a počítání kalorií.
Co nejméně kroků, žádný účet, data jen v telefonu.

## Co umí

- Jeden seznam jídel za den, přepínání dnů (včera, dnes, zítra, kalendář).
- Součet kcal a makroživin, kruhový graf vůči dennímu limitu.
- Hledání potravin: nejdřív vlastní databáze a vestavěné potraviny (offline, bez ohledu na diakritiku),
  když nic není, automaticky [Open Food Facts](https://world.openfoodfacts.org/).
- Ruční zadání názvu a kcal.
- Naposledy použité potraviny si pamatují množství, opakované jídlo jsou dvě klepnutí.
- Nastavení: pohlaví, hmotnost, výška, věk → bazální metabolismus (Mifflin-St Jeor), denní limit.

## Sestavení

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

APK najdete v `build/app/outputs/flutter-apk/app-release.apk`.

Data o potravinách pochází z Open Food Facts (licence ODbL).
