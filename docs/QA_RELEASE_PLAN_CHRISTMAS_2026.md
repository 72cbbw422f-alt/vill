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


## Uppdatering 2026-11-25 – scanner och bevarande av OCR-märkningar
- Kodgranskning av scannerflödet visade att den separata råa OCR-avläsningen för stämplar och sifferkoder visades i analysrapporten men inte följde med när föremålet sparades.
- På feature/home-collection-dashboard har SaveAntiqueSheet nu fått rawMarkingText som indata. Vanlig OCR och rå märkningstext sparas som separata, tydligt märkta anteckningsavsnitt; rå avläsning utelämnas om den är identisk med vanlig OCR för att undvika dubbletter.
- Sparaformuläret visar nu samlingens återställnings-/skrivskyddsstatus och blockerar spara-knappen när CollectionStore.loadError finns. Save-funktionen har även ett separat skydd innan add anropas.
- Berörd fil: Features/Scanner/ScannerView.swift. Commit eb349b8477196df5b980d805dce888971718cb55.
- PR #2 uppdaterad med ändringsbeskrivning och tydlig valideringsstatus. CI-körning #133 för exakt commit eb349b8477196df5b980d805dce888971718cb55 avslutades med success 2026-11-25. Simulatorbygge, osignerat iOS-enhetsbygge, IPA-paketering och artifact-uppladdning passerade.
- Ingen fysisk testning av kamera, PhotosPicker, OCR eller sparande/återöppning är genomförd. Ingen merge till main.

## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / eb349b8 | Scanner: spara både vanlig OCR och separat rå märkningstext; blockera sparande i recovery-läge | Kodändring incheckad; CI #133 pågår; fysisk QA återstår |
| 2026-11-25 | qa/christmas-release-readiness | Dokumenterade scannergranskning, ändring, berörd fil och väntande CI | Dokumentation uppdaterad |


## Uppdatering 2026-11-25 – CI #133 och IPA-verifiering för scannerändringen
- CI-körning #133 (run ID 45615541731) avslutades med success för exakt head-commit eb349b8477196df5b980d805dce888971718cb55 på feature/home-collection-dashboard.
- Samtliga steg i byggjobbet passerade: checkout, Xcode-val, appikongenerering, simulatorbygge, osignerat iOS-enhetsbygge, IPA-paketering och uppladdning.
- Artifact-ID 15022545736, namn Antikspanaren-unsigned-IPA, storlek 761 145 byte. GitHub-artifactens SHA-256 är c85a072aa405534bfd943d2b4c54a3827e6110750fb0aa2025e6a11b9b8bf22a.
- Artifact ZIP hämtades och kontrollerades lokalt. Lokal SHA-256 matchar GitHubs digest exakt. ZIP innehåller Antikspanaren-unsigned.ipa; IPA innehåller Payload/Antikspanaren.app och Info.plist.
- Verifierade Info.plist-fält: bundle identifier se.antikspanaren.app, version 0.1.0, build 1, MinimumOSVersion 17.0, UIDeviceFamily [1, 2].
- Arkivkontrollen verifierar inte kodsignering, installation eller körning. IPA är osignerad. Ingen fysisk iPhone-QA är utförd.
- Kodgranskning av Models/CollectionStore.swift visar lokal JSON-persistens med atomisk skrivning, separata JPEG-filer och rollback av in-memory-post/bild vid misslyckad add-persistens. Filnamn kontrolleras mot katalogkomponent innan bild läses eller raderas. Vid JSON-läs-/decodefel lämnas originaldata orörd och skrivningar blockeras.
- Scannerändringen i Features/Scanner/ScannerView.swift sparar nu både vanlig OCR och okorrigerad rå märkningstext som separata anteckningar med verifieringsvarning. Detta är byggverifierat, men måste fortfarande testas med verkliga foton och efter återstart.
- PR #2 är fortsatt draft/open och inte mergad. main är oförändrad på 8cde3cd6072f4c318d31aeb8ff86f68bd1d91ad9.
- Kvar: fysisk iPhone-testning av kamera, PhotosPicker, OCR, skapa/spara/återöppna, redigera/radera, flera bilder och PDF-export; därefter signering och installationskontroll.
 
## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / eb349b8 | CI #133 och nedladdad IPA kontrollerad; SHA-256 och Info.plist verifierade | CI och arkivkontroll godkända; IPA osignerad; fysisk QA återstår |
| 2026-11-25 | qa/christmas-release-readiness | Uppdaterade QA-planen med CI #133, artifact-ID/digest och kodgranskning av lokal lagring | Dokumentation uppdaterad |


## Uppdatering 2026-11-25 – kamera och bildväljare, konkurrerande bildladdning
- Kodgranskning identifierade en möjlig kapplöpning: om en bild från PhotosPicker fortfarande laddades när användaren öppnade kameran kunde den äldre asynkrona laddningen slutföras efter kamerafotot och skriva över den nytagna bilden.
- Fix på `feature/home-collection-dashboard`, commit `8b29fd05de00356247d1a40677e4a4a2927de293`, fil `Features/Scanner/ScannerView.swift`.
- När kameran öppnas invalideras nu pågående PhotosPicker-laddning via generations-ID. Valet nollställs, laddningsindikatorn stoppas och gamla analysresultat rensas.
- Nollställning av PhotosPicker-val hanteras separat så att den inte raderar en bild som kameran redan har levererat.
- Ändringen är kodgranskad men ännu inte byggverifierad. En ny PR-CI-körning för commit `8b29fd05de00356247d1a40677e4a4a2927de293` inväntas. Inga tester på fysisk enhet är utförda.
- PR #2 är fortsatt draft/open och inte mergad. `main` är oförändrad.

## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / 8b29fd0 | Invalidera pågående bildläsning från PhotosPicker när kameran öppnas; förhindra att gammal asynkron bild ersätter ny kamerabild | Kodändring incheckad; CI inväntas; fysisk QA ej utförd |
| 2026-11-25 | qa/christmas-release-readiness | Dokumenterade hittad kapplöpning, lösning och kvarvarande verifiering | Dokumentation uppdaterad |


## Uppdatering 2026-11-25 – CI #134, IPA-kontroll och korrigerad kamerarace
- CI #134 (run ID 45632920718) avslutades med success för commit `8b29fd05de00356247d1a40677e4a4a2927de293`. Samtliga steg passerade: checkout, Xcode-val, appikon, simulatorbygge, osignerat iOS-enhetsbygge, IPA-paketering och uppladdning.
- Artifact-ID `15032281937`, `Antikspanaren-unsigned-IPA`, 760 655 byte. SHA-256 verifierad lokalt och matchar GitHub-digest: `08562522824112b640940af60bedf5508d162f47021de931fff5b9cb08eb2cf5`.
- ZIP innehåller `Antikspanaren-unsigned.ipa`; IPA innehåller `Payload/Antikspanaren.app`. Info.plist verifierad: bundle ID `se.antikspanaren.app`, version `0.1.0`, build `1`, minimum iOS `17.0`, enhetsfamilj `[1, 2]`. Kamerabehörighetens användningstext finns.
- Viktig rättelse efter ytterligare granskning: commit `8b29fd0` invaliderade inte faktiskt bildladdningen i kameraknappens action. Hjälpfunktionen/hanteringen av null-val fanns, men kameraknappen anropade inte invalideringen. Därför var den dokumenterade kamerarace-fixen inte fullständigt inkopplad i den commit som CI #134 byggde.
- Korrigering incheckad på samma feature-branch i commit `2569d8dd92e326014a011623581e96d0ed382aa3`, fil `Features/Scanner/ScannerView.swift`: kameraknappen anropar nu `openCamera()`, som först byter generations-ID (invaliderar pågående PhotosPicker-load), nollställer valt foto/laddningsstatus/fel, rensar gammal bild och analys och öppnar därefter kameran.
- CI #134 verifierar alltså commit `8b29fd0`, inte den nyare korrigeringen `2569d8d`. Ny CI för `2569d8d` inväntas; den nya ändringen är ännu inte byggverifierad.
- Ingen fysisk iPhone-QA har utförts. IPA är osignerad; signering, installation och verklig kamera-/bildväljar-/OCR-testning återstår.
- PR #2 är draft/open och ej mergad. `main` är oförändrad på `8cde3cd6072f4c318d31aeb8ff86f68bd1d91ad9`.

## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / 8b29fd0 | CI #134 och IPA-kontroll; SHA-256 och Info.plist verifierade | CI och arkivkontroll godkända för 8b29fd0; IPA osignerad |
| 2026-11-25 | feature/home-collection-dashboard / 2569d8d | Kopplade kameraknappen till openCamera() så PhotosPicker-load invalideras före kamerastart | Kod incheckad; ny CI inväntas; fysisk QA ej utförd |
| 2026-11-25 | qa/christmas-release-readiness | Dokumenterade CI #134, artifactdigest, IPA-metadata och rättelsen av den ofullständiga tidigare kamerafixen | Dokumentation uppdaterad |


## Uppdatering 2026-11-25 – CI #135 och slutlig kamerakorrigering
- CI #135 (run ID `45633752988`) avslutades med `success` för exakt feature-head `2569d8dd92e326014a011623581e96d0ed382aa3`.
- Samtliga åtta steg passerade: checkout, Xcode-val, appikon, simulatorbygge, osignerat iOS-enhetsbygge, IPA-paketering och artifact-uppladdning.
- Artifact-ID `15031154900`, namn `Antikspanaren-unsigned-IPA`, storlek 761 462 byte. Nedladdad ZIP verifierad lokalt; SHA-256 `91289ae37e7c899092957c7b7b93ea5b8d75ea16030b674ab4495c5e02896d51` matchar GitHubs digest.
- ZIP innehåller `Antikspanaren-unsigned.ipa`; IPA innehåller `Payload/Antikspanaren.app`. Info.plist verifierad: bundle ID `se.antikspanaren.app`, version `0.1.0`, build `1`, minimum iOS `17.0`, enhetsfamilj `[1, 2]`, kamerabeskrivning finns. Körbar fil är Mach-O 64-bit arm64.
- Detta är bygg- och arkivverifiering, inte signerings-, installations- eller runtime-verifiering. IPA är osignerad.
- Den fullständiga kameraknappskopplingen i commit `2569d8d` är därmed byggverifierad. Kamera och PhotosPicker måste fortfarande testas fysiskt.
- PR #2 är draft/open, ej mergad. `main` är oförändrad på `8cde3cd6072f4c318d31aeb8ff86f68bd1d91ad9`.

## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / 2569d8d | CI #135, nedladdad IPA, SHA-256 och Info.plist/Mach-O kontrollerade | Alla byggsteg godkända; arkiv verifierat; osignerad IPA |
| 2026-11-25 | qa/christmas-release-readiness | Dokumenterade slutlig CI #135 och verifierad IPA för exakt feature-head | Dokumentation uppdaterad |


## Uppdatering 2026-11-25 – tydligare felhantering vid import av extrabilder
- Kodgranskning av `AntiqueDetailView.importSelectedImages` visade att misslyckad `PhotosPickerItem.loadTransferable` eller ogiltig bilddata tidigare ignorerades tyst. Användaren kunde därför inte se att en eller flera valda bilder aldrig lades till.
- Ändrat på `feature/home-collection-dashboard`, commit `2012831ab4d578cf1f3ffc4cda3d18eb2d201dec`, fil `Features/Collection/AntiqueDetailView.swift`.
- Importen räknar nu misslyckade bilder och visar ett tydligt resultat efter batchen: alla misslyckades, vissa misslyckades eller samtliga lades till. Första konkreta felorsaken visas när den finns.
- Befintligt generationsskydd är kvar: en äldre import får inte rensa en nyare PhotosPicker-selektion. Varje bild som lyckas sparas via befintlig atomisk `CollectionStore.addImage`-funktion.
- Ändringen är incheckad men ännu inte byggverifierad. CI för exakt commit `2012831` inväntas. Fysisk iPhone-testning av flerbildsimport återstår.
- CI #135 för föregående commit `2569d8d` är godkänd; den verifierar inte den nya felhanteringen.
- PR #2 är fortsatt draft/open och ej mergad. `main` är oförändrad.

## Arbetslogg – tillägg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | feature/home-collection-dashboard / 2012831 | Visa antal misslyckade extrabildsimporter och första felorsak i stället för att ignorera fel tyst | Kod incheckad; ny CI inväntas; fysisk QA återstår |
| 2026-11-25 | qa/christmas-release-readiness | Dokumenterade importfelhantering och tydlig gräns mellan föregående CI och senaste commit | Dokumentation uppdaterad |
