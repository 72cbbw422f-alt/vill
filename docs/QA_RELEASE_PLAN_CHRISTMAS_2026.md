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
- CI-körning #128 för PR #1 avslutades med `success` 2026-11-25. Alla åtta steg passerade: checkout, Xcode-val, appikon, simulatorbygge, iOS-enhetsbygge, IPA-paketering och uppladdning.
- Artifact `Antikspanaren-unsigned-IPA` skapades (ca 727 kB; SHA-256 `acc77bdf35b819951dac935ea47f64b9bb10338256cc6fb125cd95692408880a`). Artifact är osignerad och har inte installerats på fysisk iPhone.
- PR #1 är fortsatt draft och ej mergad. Ingen ändring har gjorts på `main`.
- Berörd kodfil: `Features/Collection/AntiqueDetailView.swift`.

## Uppdatering 2026-11-25 – startsidans samlingsöversikt
- Ny oberoende feature-branch: `feature/home-collection-dashboard`.
- PR #2: https://github.com/72cbbw422f-alt/vill/pull/2
- Commit `d023e53b7b99f59dcaa3a34904ef9f3183292025`.
- `Features/Home/HomeView.swift` visar nu upp till två senast sparade föremål med bild, tillverkare, antal bilder och prisreferenser. Tom samling får en särskild vägledande vy.
- Ändringen använder befintlig lokal `CollectionStore`; inga externa tjänster eller kostnader tillkommer.
- PR #2 är staplad ovanpå PR #1 (`fix/pdf-evidence-compiler-complexity`) eftersom basgrenen `main` ännu innehåller det tidigare kompilatorfelet. PR #1 måste integreras före PR #2.
- CI-körning #129 och #130 startades mot tidigare bas `main`; de är inte slutlig verifiering av den staplade PR:en. Ny CI inväntas efter ändringen av PR-bas. Fysisk visuell kontroll är inte genomförd.
- Ingen merge till `main` har gjorts.

## Releasebeslut
Release får godkännas först när CI och IPA-grindarna är gröna, installation är verifierad på fysisk iPhone och alla funktioner som marknadsförs som fungerande har dokumenterade testresultat. Externa källor som inte kan verifieras ska uttryckligen anges som ej tillgängliga eller ej färdiga.

## Arbetslogg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | `qa/christmas-release-readiness` / bas `8cde3cd` | Skapade QA- och releaseplan; begärde omkörning av tidigare avbruten CI-körning #127 | Dokumentation skapad |
| 2026-11-25 | `fix/pdf-evidence-compiler-complexity` / `73922b3` | Förenklade PDF-detaljsträngar; CI #128 | Simulator, iOS-enhetsbygge och osignerad IPA godkända; PR #1 ej mergad |
| 2026-11-25 | `feature/home-collection-dashboard` / `d023e53` | Startsidan visar senaste sparade föremål; PR #2 | Ny CI efter basändring inväntas; fysisk QA ej utförd |


## Uppdatering 2026-11-25 – CI-felsökning och konsoliderad PR
- Körning #129 och #130 för PR #2 misslyckades eftersom de byggde merge-commit mot gamla `main`; logg bekräftar samma tidigare fel i `AntiqueDetailView.swift:792`, inte ett nytt fel i startsidan.
- PR #2 har gjorts fristående mot `main` och innehåller den verifierade PDF-kompilatorfixen tillsammans med startsidans samlingsöversikt.
- Startsidan sorterar nu de två senaste posterna efter `createdAt` och har förbättrade VoiceOver-hintar för öppning av föremål.
- Ny CI #131 för commit `39e0a30267994a4ab3f9467e9cb38d98efc26b8e` är köad. Slutresultat inväntas.
- PR #1 hålls öppen tills #2 har verifierats; därefter kan #1 stängas som ersatt, utan merge.

- Ytterligare kodgranskning av startsidan upptäckte att ett läsfel i lokal samlingsdata annars kunde presenteras som en tom samling. Startsidan visar nu samma skrivskyddade återställningsmeddelande som samlingsvyn när `CollectionStore.loadError` finns. Commit `a20df1469613dbe3dd0452832427a6e50d14a8b7`; CI-körning #132 för denna senaste commit `a20df1469613dbe3dd0452832427a6e50d14a8b7` är köad. Även körning #131 för föregående commit är köad; slutligt resultat inväntas.


## Uppdatering 2026-11-25 – slutligt CI-resultat för PR #2
- CI-körning #132 för exakt head-commit a20df1469613dbe3dd0452832427a6e50d14a8b7 avslutades med success.
- Samtliga byggsteg passerade: checkout, Xcode-val, generering av appikon, simulatorbygge, osignerat iOS-enhetsbygge, IPA-paketering och uppladdning av artifact.
- Artifact: Antikspanaren-unsigned-IPA, 757 917 byte (cirka 740 KiB), SHA-256 9c6b3f0d75d242818790204eb3cfa8aae026069e2bbf12caf3b8bab305eadf62.
- Artifact-ID: 15003968137. GitHub anger att artifacten upphör 2026-12-09 08:27 UTC. Den är osignerad; innehållsstruktur, signering och fysisk installation är ännu inte verifierade.
- PR #2 är fortsatt öppen och draft. main står kvar på 8cde3cd6072f4c318d31aeb8ff86f68bd1d91ad9; ingen merge har utförts.
- PR #2 innehåller två kodfiler: Features/Collection/AntiqueDetailView.swift och Features/Home/HomeView.swift.
- Kodgranskning bekräftar att MainTabView äger och injicerar samma CollectionStore som används av startsidan och samlingsvyn. Lagringen är lokal JSON med separat bildmapp. Vid JSON-läsfel lämnas originalfilen orörd och skrivningar blockeras.
- Körning #131 avser föregående commit och är inte den auktoritativa verifieringen av PR:ens senaste head. #132 är den gröna körningen för aktuell commit.
- Nästa steg: granska och verifiera IPA-arkivet, uppdatera PR-beskrivningen vid behov och genomföra fysisk iPhone-QA när signerad installation finns tillgänglig. PR #1 är överlappande och ska inte mergas separat.

## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / a20df14 | CI #132: simulator, osignerat iOS-bygge, IPA-paketering och artifact-uppladdning | Alla steg godkända; osignerad IPA 757 917 byte; fysisk installation ej verifierad |
| 2026-11-25 | qa/christmas-release-readiness | Dokumenterade #132, artifact-ID, SHA-256, PR- och main-status samt kodgranskning av CollectionStore-injektion och återställningsskydd | Dokumentation uppdaterad |


## Uppdatering 2026-11-25 – kontroll av nedladdad IPA
- Artifact ZIP laddades ned från GitHub Actions och SHA-256 verifierades lokalt: 9c6b3f0d75d242818790204eb3cfa8aae026069e2bbf12caf3b8bab305eadf62 (matchar GitHub-artifactens digest).
- ZIP-arkivet innehåller Antikspanaren-unsigned.ipa. IPA-arkivet kunde öppnas och innehåller Payload/Antikspanaren.app samt appens körbara fil, Assets.car och Info.plist.
- Info.plist verifierad: bundle identifier se.antikspanaren.app, version 0.1.0 (build 1), MinimumOSVersion 17.0, iPhone/iPad-enhetsfamilj [1, 2], LSRequiresIPhoneOS true.
- Appens binär identifieras som Mach-O 64-bit arm64.
- Detta verifierar arkivets integritet och grundläggande IPA-struktur, inte kodsignering, installation eller körning. Ingen fysisk iPhone har testats.
