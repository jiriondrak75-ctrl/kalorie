# Kalorie – jednoduchý tracker kalorií (Flutter)

Osobní mobilní aplikace pro zapisování snědeného jídla a počítání kalorií.
Hlavní zásada: **co nejméně kroků a žádné zbytečnosti.** Každá nová funkce musí obhájit, proč tu je.

## Co aplikace umí (a nic víc)

- Jeden seznam jídel za den. **Žádné členění na snídani, oběd a večeři.**
- Přepínání dnů: včera, dnes, zítra a libovolný den přes kalendář. Jídlo jde přidat i dopředu.
- Součet kcal za den a pod ním souhrn makroživin (bílkoviny, sacharidy, tuky), pokud jsou k dispozici.
- Nastavení (ikona vpravo nahoře): pohlaví, hmotnost, výška, věk → bazální metabolismus (Mifflin-St Jeor, `Settings.bmr`), a denní limit kcal. Když je limit zadaný, součet je uvnitř kruhového grafu se „zbývá X“ (nad limitem červeně „přes o X“).
- Přidání jídla:
  - Při psaní se živě filtrují naposledy použité a vestavěné potraviny, bez sítě a bez ohledu na diakritiku.
  - Když lokálně nic není (a dotaz má aspoň 3 znaky), spustí se hledání v Open Food Facts samo, 0,8 s po dopsání. Enter ho spustí vždy.
  - Každá přidaná potravina (i z OFF a ručně zadaná) se uloží do `recent`, které slouží jako vlastní databáze (max. 1000 položek).
  - „Zadat ručně“ uloží jen název a celkové kcal.
- Naposledy použité potraviny si pamatují poslední množství, takže opakované jídlo jsou dvě klepnutí.
- Klepnutí na záznam změní množství, swipe doleva ho smaže (s možností vrátit).
- Data jsou jen lokálně v telefonu. Žádný účet, žádný backend.

## Struktura

```
lib/
  main.dart                 MaterialApp, téma, česká lokalizace
  models.dart               Food, Entry, norm(), fmtNum(), parseNum()
  storage.dart              Store – shared_preferences, klíč day_YYYY-MM-DD + recent
  off_api.dart              Open Food Facts search (bez API klíče)
  builtin_foods.dart        základní potraviny s orientačními hodnotami na 100 g
  screens/home_screen.dart  den, součet, seznam
  screens/search_screen.dart hledání + ruční zadání
  screens/settings_screen.dart tělesné údaje, BMR a denní limit (ukládá průběžně)
  widgets/kcal_ring.dart    kruhový graf snědeno / limit (CustomPainter, bez knihovny)
  theme.dart                barvy a ThemeData převzaté z Nákupního seznamu
  widgets/amount_sheet.dart spodní panel pro množství
  widgets/row_card.dart     zaoblený řádek seznamu (sdílený vzhled)
```

Model: `Food.kcal` (a makra) jsou na 100 g, nebo na 1 porci, když `perServing == true`.
`Entry` drží celou kopii `Food` a množství, takže změna databáze potravin nemění historii.

## Design – převzít z projektu `D:\projekty\nakupniseznam\`

Vizuál má odpovídat aplikaci Nákupní seznam. Než začneš měnit UI:

1. Zpřístupni si složku (je mimo tento projekt): `/add-dir D:\projekty\nakupniseznam`
   nebo spusť Claude Code s `--add-dir D:\projekty\nakupniseznam`.
2. Projdi tam hlavně tyto části:
   - `lib/main.dart`
   - soubory s tématem (`theme*.dart`, `colors*.dart`, `app_theme*`, `styles*`)
   - `pubspec.yaml` (fonty, balíčky jako google_fonts)
   - sdílené widgety (`lib/widgets/`)
   - hlavní obrazovku seznamu
3. Vypiš si design tokeny, které tam najdeš:
   - barvy a seed barvu
   - světlý a tmavý režim
   - font a typografickou škálu
   - zaoblení, rozestupy a výšky řádků
   - styl AppBaru, FAB, ListTile, bottom sheetů a dialogů
   - ikony a animace
4. Zapiš je do sekce **Design tokeny** níže, abys je příště nemusel hledat znovu.
5. Přenes téma do `lib/theme.dart` (ne inline do widgetů) a použij ho v `main.dart`.
6. Sjednoť obrazovky: hlavní obrazovka by se měla chovat a vypadat jako seznam v Nákupním seznamu. Řádky, swipe, prázdný stav i FAB mají působit stejně.

Pravidla:
- Kód z `nakupniseznam` **jen čti, nikdy ho neupravuj.**
- Přebírej vizuál a vzory UI, ne logiku. Datový model a chování kalorií zůstávají tak, jak jsou popsané výše.
- Pokud Nákupní seznam používá balíček, který tu chybí (např. fonty), přidej ho jen tehdy, když je nutný pro vzhled.
- Když se design v něčem nedá přenést 1:1, zvol nejjednodušší variantu a napiš proč.

### Design tokeny

Zdroj: `nakupniseznam/lib/main.dart` (celá aplikace je v jednom souboru, téma je inline). Převedeno do `lib/theme.dart`.

- **Režim:** pouze tmavý (`Brightness.dark`, M3). Světlý režim Nákupní seznam nemá, proto ani tady není.
- **Barvy:** pozadí `#28282B`, surface (AppBar, řádky) `#111111`, surfaceVariant (dialogy, sheety) `#1E1E1E`,
  primary `#0E639C`, secondary `#1177BB`, text `#D4D4D4`, tlumený text/ikony `#858585`, swipe pozadí `Colors.red.shade900`. Žádná seed barva, `ColorScheme.dark(...)` ručně.
- **Font:** Nunito přes `google_fonts` (`GoogleFonts.nunitoTextTheme`). Titulek AppBaru 18 / w700, text řádku 15, prázdný stav 16 tlumeně.
- **Zaoblení:** řádky a swipe pozadí 12. Bottom sheet 16 nahoře (doplněno, Nákupní seznam sheet nemá).
- **Rozestupy:** `scale = šířka / 360`; seznam padding 16×12 · scale, mezera mezi řádky 10 · scale, swipe ikona odsazená 20 · scale.
- **AppBar:** pozadí surface, elevation 0, bez surface tint, `leading` = bílá ikona s paddingem 10, akce v tlumené barvě.
- **Řádek:** `Material(color: surface, radius 12)` + `InkWell`, žádné ListTile. Sdílený widget `widgets/row_card.dart`.
- **Swipe:** `Dismissible` endToStart, červené zaoblené pozadí, ikona `Icons.delete` bílá vpravo.
- **FAB:** černý, bílá ikona `Icons.add`, elevation 2.
- **Dialogy:** pozadí surfaceVariant, „Zrušit“ jako tlumený `TextButton`, potvrzení `FilledButton`.
- **Animace:** jen výchozí Material.

Odchylky: Nákupní seznam má v řádku i tlačítko koše. Tady se maže jen swipem, protože to tak chce zadání (a snackbar „Vrátit“ je navíc).

<!-- Doplní Claude Code po prozkoumání D:\projekty\nakupniseznam -->

## Zdroje dat

- **Open Food Facts:** hlavně `search.openfoodfacts.org/search?q=…&langs=cs,en` (odpověď v `hits`, `brands` je seznam).
  Záloha je starý `world.openfoodfacts.org/cgi/search.pl` (odpověď v `products`), který často vrací 503.
  - Je bez klíče. V hlavičce vždy posílej `User-Agent`.
  - Limit je zhruba 10 vyhledávání za minutu, proto **nehledat při každém písmenu**: jen na Enter, nebo automaticky s prodlevou 0,8 s, když nic nenajde lokální hledání.
  - Neexistující produkt může vrátit HTTP 200, takže kontroluj obsah odpovědi.
- **Vestavěné potraviny** (`builtin_foods.dart`) mají orientační hodnoty. Slouží pro obecné věci, které v OFF chybí (rohlík, vejce, pivo).
- **Možné rozšíření:** Kalorické tabulky nemají veřejné API. Neoficiální endpointy (`?format=json`) jsou pouze pro osobní, nekomerční použití. Pokud se přidají, tak jedině jako samostatný adaptér za společným rozhraním, aby šly snadno vypnout.

## Pravidla pro kód

- UI texty jsou česky, identifikátory anglicky.
- Čísla zobrazuj s desetinnou čárkou (`fmtNum`) a vstup parsuj přes `parseNum` (přijímá čárku i tečku).
- Žádný state management framework, dokud nebude opravdu potřeba. Stačí `StatefulWidget`.
- Žádné nové závislosti bez důvodu.
- Po `await` vždy kontroluj `mounted` a `context.mounted`.
- Datum počítej přes `DateTime(y, m, d ± n)`, ne přes `Duration`, kvůli letnímu času.
- Formátuj přes `dart format`. Před dokončením úkolu musí `flutter analyze` projít bez chyb.

## Příkazy

```bash
flutter pub get
flutter analyze
flutter run
flutter build apk --release
dart run flutter_launcher_icons   # po změně ikony v ico/
```

Ikona: `ico/kalorie.jpg` (zdroj) a `ico/kalorie_foreground.png` (stejný obrázek zmenšený na 62 % s černým okrajem pro adaptivní ikonu Androidu 8+, který ořezává okraje).

Pro release na Androidu je v `android/app/src/main/AndroidManifest.xml` nutné:
`<uses-permission android:name="android.permission.INTERNET"/>`

## Nápady na později (nedělat bez zadání)

- Skenování čárového kódu (`mobile_scanner` + `api/v2/product/<kód>.json`)
- Export a záloha dat
