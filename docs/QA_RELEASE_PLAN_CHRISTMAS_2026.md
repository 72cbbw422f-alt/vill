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
- Senaste körningen vid baslinjen (#127) hade conclusion `failure`; jobbet var `cancelled` och hade inga steg registrerade. En omkörning begärdes 2026-11-25 och behöver följas upp.
- Historisk lyckad körning #123 byggde simulator, osignerad iOS-app och laddade upp IPA-artifact. Detta är inte bevis för fysisk enhetsinstallation.
- README anger lokal lagring och kamerabaserad scanner. Externa auktionsintegrationer och fysisk iPhone-QA är inte verifierade.

## Releasegrindar

### A. CI och kompilering
- [ ] Senaste huvudgrenens CI avslutas med success.
- [ ] Simulatorbyggning godkänd.
- [ ] Releasebyggning för generisk iOS-enhet godkänd.
- [ ] Appikon genereras utan fel.
- [ ] CI-loggar och commit-SHA sparas i releaseprotokollet.

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

## Releasebeslut
Release får godkännas först när CI och IPA-grindarna är gröna, installation är verifierad på fysisk iPhone och alla funktioner som marknadsförs som fungerande har dokumenterade testresultat. Externa källor som inte kan verifieras ska uttryckligen anges som ej tillgängliga eller ej färdiga.

## Arbetslogg
| Datum | Gren/commit | Ändring/test | Resultat |
|---|---|---|---|
| 2026-11-25 | `qa/christmas-release-readiness` / bas `8cde3cd` | Skapade QA- och releaseplan; begärde omkörning av tidigare avbruten CI-körning #127 | Dokumentation skapad; CI-omkörning inväntas |
