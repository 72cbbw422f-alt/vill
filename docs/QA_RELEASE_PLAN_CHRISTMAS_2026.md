# Antikspanaren – QA- och releaseplan inför jul 2026

## Syfte
Säkerställa att en stabil, installerbar iPhone-version kan överlämnas som julklapp. Stabilitet och verifierad funktion prioriteras framför antal funktioner.

## Arbetsregler
- Bygg endast från en granskad, integrerad commit.
- Håll CI, IPA-paketering, signering och fysisk iPhone-verifiering som separata kvalitetsgrindar.
- Testa Auctionet, Catawiki, Barnebys och Bukowskis var för sig.
- Använd inte syntetiska objekt som produktionsdata.
- Spara testdatum, commit, iOS-version, enhetsmodell, teststeg och faktisk utgång.
- Markera aldrig en funktion som verifierad enbart för att den kompilerar.

## Statusdefinitioner
- **Verifierat:** test utfört med dokumenterat godkänt resultat.
- **Delvis testat:** vissa delar testade, men inte hela flödet.
- **Ej verifierat:** saknar praktiskt testunderlag.
- **Underkänt:** test utfört och misslyckats.

## Känd baslinje vid start
- Repository: `72cbbw422f-alt/vill`
- Basgren: `main`
- Bascommit: `8cde3cd6072f4c318d31aeb8ff86f68bd1d91ad9`
- iOS deployment target: 17.0
- Xcode-projekt: `Antikspanaren.xcodeproj`
- Delat schema: `Antikspanaren`
- CI-workflow: `.github/workflows/ios-build.yml`
- XcodeGen: inte konfigurerat; projektet är ett native Xcode-projekt.
- Separat XCTest-target: inte identifierat i projektfilen.
- Baslinjekörning #127 misslyckades i simulatorbygget på grund av ett Swift-kompilatorfel. Korrigeringen på PR #1 verifierades därefter med fullständigt godkänd CI-körning #128.
- Historisk lyckad körning #123 byggde simulator, osignerad iOS-app och laddade upp IPA-artifact. Detta är inte bevis för fysisk enhetsinstallation.
- README anger lokal lagring och kamerabaserad scanner. Externa auktionsintegrationer och fysisk iPhone-QA är inte verifierade.

## Releasegrindar

### A. CI och kompilering
- [x] CI-körning #128 för korrigerings-PR #1 avslutades med success.
- [x] Simulatorbyggning godkänd i #128.
- [x] Releasebyggning för generisk iOS-enhet godkänd i #128.
- [x] Appikon genereras utan fel i #128.
- [x] CI-loggar och commit-SHA dokumenterade för #128.
- [ ] Ändringen är ännu inte integrerad i `main`; huvudgrenens releasegrind är därför inte slutligt godkänd.

### B. IPA och signering
- [ ] IPA-artifact finns för exakt releasecommit.
- [ ] IPA kan packas upp och innehåller `Payload/Antikspanaren.app`.
- [ ] Bundle identifier och versionsnummer kontrolleras.
- [ ] IPA signeras med en metod som fungerar för mottagarens enhet.
- [ ] Installerad app startar efter installation.
- [ ] Giltighetstid och eventuell förnyelsebegränsning dokumenteras.

### C. Fysisk iPhone
- [ ] Första start och navigation.
- [ ] Kameraåtkomst och fotografering.
- [ ] Bildväljare.
- [ ] OCR/Vision-resultat presenteras som förslag, inte verifierade fakta.
- [ ] Skapa, redigera och radera föremål.
- [ ] Flera bilder, omslagsbild och borttagning av extrabild.
- [ ] Appen återstartas och lokala data finns kvar.
- [ ] Tomma fält, långa texter, avbrutna flöden och nekade behörigheter hanteras.

### D. Samling, sökning och värderingsunderlag
- [ ] Sökning och filtrering.
- [ ] Sortering.
- [ ] Favoriter.
- [ ] Prisreferenser: slutpris, begärt pris, auktionsvärdering och expertbedömning hålls isär.
- [ ] Källa, datum, skick och jämförbarhet visas korrekt.
- [ ] Redigering och radering bevarar övriga uppgifter.
- [ ] Bakåtkompatibilitet för tidigare sparade objekt.

### E. Externa auktionskällor – separat per källa
För varje källa ska testprotokollet innehålla källa, testtid, URL, HTTP-/åtkomstutfall, objekt-ID, titel, beskrivning, bilder, pris/bud, valuta, sluttid/tidszon och felhantering.

| Källa | Hämtning | Objektdata | Bilder | Pris/bud | Sluttid | Felhantering |
|---|---|---|---|---|---|---|
| Auctionet | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat |
| Catawiki | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat |
| Barnebys | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat |
| Bukowskis | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat | Ej verifierat |

Ingen källa får markeras som fungerande förrän en verklig, aktuell listning har testats. Om åtkomst saknas eller plattformsvillkor hindrar hämtning ska det dokumenteras, inte kringgås.

### F. Bevakningar och notiser
- [ ] Lägg till och ta bort bevakning.
- [ ] Bevakad sökning och kategori.
- [ ] Auktionsslut och tidszon.
- [ ] Dubbletter och upprepade notiser.
- [ ] Behörighet nekad.
- [ ] Källa otillgänglig eller objekt borttaget.
- [ ] Notis öppnar rätt objekt.

### G. Regression och prestanda
- [ ] Snabb uppstart och navigation.
- [ ] Stora bildgallerier.
- [ ] Stora samlingar.
- [ ] Upprepade nätverksfel och återhämtning.
- [ ] Ingen förlust av lokala data.
- [ ] Ingen oavsiktlig nätverks- eller batteribelastning.


## Uppdatering 2026-11-25 – byggfel och korrigering
- Omkörning av main-körning #127 (commit `8cde3cd`) avslutades med failure.
- Appikongenerering lyckades. Simulatorbygget föll i `Features/Collection/AntiqueDetailView.swift:792` med Swift-kompilatorfelet "unable to type-check this expression in reasonable time".
- Orsaken lokaliserades till sammansättningen av prisreferensens PDF-detaljer.
- En avgränsad korrigering har gjorts på `fix/pdf-evidence-compiler-complexity`, commit `73922b37077cf735ec1088211d8fdcbf6b87a9d7`.
- Ändringen ersätter den komplexa array-/optional-kedjan med en explicit `[String]` och stegvisa tillägg. Samma etiketter och innehåll behålls.
- Draft PR: https://github.com/72cbbw422f-alt/vill/pull/1
- CI-körning #128 för PR-commiten avslutades med `success` 2026-11-25. Alla åtta steg passerade: checkout, Xcode-val, appikon, simulatorbygge, iOS-enhetsbygge, IPA-paketering och uppladdning.
- Artifact `Antikspanaren-unsigned-IPA` skapades (ca 727 kB; SHA-256 `acc77bdf35b819951dac935ea47f64b9bb10338256cc6fb125cd95692408880a`). Artifact är osignerad och har inte installerats på fysisk iPhone.
- PR #1 är fortsatt draft och ej mergad. Ingen ändring har gjorts på `main`.
- Berörd kodfil: `Features/Collection/AntiqueDetailView.swift`.

## Uppdatering 2026-11-25 – startsidans samlingsöversikt
- Ny oberoende feature-branch: `feature/home-collection-dashboard`.
- PR #2: https://github.com/72cbbw422f-alt/vill/pull/2
- Commit `d023e53b7b99f59dcaa3a34904ef9f3183292025`.
- `Features/Home/HomeView.swift` visar nu upp till två senast sparade föremål med bild, tillverkare, antal bilder och prisreferenser. Tom samling får en särskild vägledande vy.
- Ändringen använder befintlig lokal `CollectionStore`; inga externa tjänster eller kostnader tillkommer.
- CI-körning #129 pågår vid dokumentationstillfället. Fysisk visuell kontroll är inte genomförd.
- Ingen merge till `main` har gjorts.

## Releasebeslut
Release får godkännas först när CI och IPA-grindarna är gröna, installation är verifierad på fysisk iPhone och alla funktioner som marknadsförs som fungerande har dokumenterade testresultat. Externa källor som inte kan verifieras ska uttryckligen anges som ej tillgängliga eller ej färdiga.

## Arbetslogg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | `qa/christmas-release-readiness` / bas `8cde3cd` | Skapade QA- och releaseplan; begärde omkörning av tidigare avbruten CI-körning #127 | Dokumentation skapad |
| 2026-11-25 | `fix/pdf-evidence-compiler-complexity` / `73922b3` | Förenklade PDF-detaljsträngar; CI #128 | Simulator, iOS-enhetsbygge och osignerad IPA godkända; PR #1 ej mergad |
| 2026-11-25 | `feature/home-collection-dashboard` / `d023e53` | Startsidan visar senaste sparade föremål; PR #2 | CI #129 inväntas; fysisk QA ej utförd |
