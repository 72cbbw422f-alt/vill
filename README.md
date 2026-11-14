# Antikspanaren

En iPhone-app för att undersöka, identifiera och värdera antikviteter, konst och kuriosa.

## Produktkrav: helt kostnadsfri
Antikspanaren ska vara gratis att använda för både användaren och utvecklaren.
- Inga prenumerationer, köp i appen, krediter eller premiumfunktioner.
- Ingen betald AI-tjänst eller extern API som debiteras per anrop.
- Ingen egen backend med löpande driftkostnad.
- Lokal lagring och Apples inbyggda funktioner prioriteras.
- Funktioner som kräver betald datalicens eller drift ska inte byggas in.

## Designidentitet
**Ett anrikt auktionshus möter modern teknik.**

- Djup antikgrön, pergament, valnöt och oxiderad mässing
- Klassisk serif-typografi och diskreta ornament
- Föremålsfotografin i centrum
- Ett tidlöst uttryck utan att kompromissa med läsbarhet och enkel användning

## Projektstruktur

```text
Antikspanaren/
├── AntikspanarenApp.swift
├── Navigation/
│   └── MainTabView.swift
├── Theme/
│   └── AntiqueTheme.swift
├── Features/
│   ├── Home/HomeView.swift
│   ├── Scanner/ScannerView.swift
│   └── Collection/
│       ├── CollectionView.swift
│       └── AntiqueDetailView.swift
└── Models/
    ├── AntiqueItem.swift
    ├── Valuation.swift
    └── CollectionStore.swift
```

## Status – grundversion
- [x] SwiftUI-appens startpunkt och navigation
- [x] Antikt färg- och typografisystem
- [x] Omarbetad startsida, samlingsvy och informationsvy
- [x] Scanner med kamera och bildbibliotek
- [x] Kostnadsfri textigenkänning direkt på enheten med Apple Vision
- [x] Kostnadsfri generell bildklassificering lokalt med Vision för breda visuella ledtrådar
- [x] Visa avläst text och spara den tillsammans med föremålets anteckningar
- [x] Spara föremål med namn, tillverkare, inköpspris och egna anteckningar
- [x] Lokal lagring av föremålsdata och bildfiler
- [x] Detaljvy för varje sparat föremål
- [x] Redigera grunduppgifter, material, period, skick, märkningar och proveniens
- [x] Flera bilder per föremål
- [x] Ta bort enskilda extrabilder utan att radera omslagsbilden
- [x] Manuellt prisintervall och anteckningar om värderingsunderlag
- [x] Prisreferenser med källa och åtskillnad mellan slutpris, begärt pris, auktionsvärdering och expertbedömning
- [x] Radera föremål och dess lokala bilder
- [x] Bakåtkompatibel avkodning av tidigare sparade föremål
- [x] Radera enskilda prisreferenser
- [x] Redigera enskilda prisreferenser
- [ ] Specialiserad bildbaserad antikidentifiering utan betald molntjänst
- [ ] Källbelagd automatisk värdering från kostnadsfria och tillåtna källor
- [x] Grundläggande Xcode-projekt med delat schema och appens behörighetsbeskrivning
- [ ] Xcode-build och simulator-/enhetstest
- [ ] Appikon och slutlig visuell QA
- [ ] IPA-export och signeringsflöde för sidladdning

## Integritet och behörigheter
När Xcode-projektet sätts upp måste appens `Info.plist` innehålla `NSCameraUsageDescription` med en tydlig svensk förklaring till varför kameran används. Bildbiblioteket hanteras via PhotosPicker och kräver inte generell åtkomst till hela bildbiblioteket.

Föremålsuppgifter och bildfiler sparas lokalt i appens dokumentkatalog. Ingen molnsynkronisering är implementerad. Textigenkänningen använder Apples Vision-ramverk lokalt på enheten; bilder skickas inte till en extern tjänst.

## Kvalitetsprinciper
1. Avläst text och automatiska förslag får aldrig presenteras som verifierade fakta.
2. Begärt pris, auktionsvärdering och faktiskt slutpris ska hållas isär.
3. Värderingar ska visa källor, datum och jämförbarhet.
4. Osäkerhet ska visas tydligt.
5. Föremålets skick, proveniens och eventuella renoveringar ska vägas in.
6. Ingen funktion får införa en löpande kostnad för användaren eller utvecklaren.

## Byggstatus
Detta repo innehåller SwiftUI-källkod och ett första native Xcode-projekt (`Antikspanaren.xcodeproj`) med delat byggschema och svensk kamerabehörighet. Projektet och källkoden har ännu inte verifierats genom en Xcode-build. Signering och IPA-export återstår. Bildklassificeringen är generell och ska inte tolkas som en expertbedömning av antikviteter. Rekommenderad bas är iOS 17 eller senare.

För sidladdning behöver IPA-filen signeras. Gratis signering via Apple-ID har normalt en begränsad giltighetstid och måste förnyas regelbundet; det är en distributionsbegränsning, inte en kostnad från Antikspanaren.
