# Antikspanaren

En iPhone-app för att undersöka, identifiera och värdera antikviteter, konst och kuriosa.

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
- [ ] Bildanalys och AI-identifiering
- [ ] Källbelagd automatisk värdering
- [ ] Xcode-projekt och bygg-/testpipeline

## Integritet och behörigheter
När Xcode-projektet sätts upp måste appens `Info.plist` innehålla `NSCameraUsageDescription` med en tydlig svensk förklaring till varför kameran används. Bildbiblioteket hanteras via PhotosPicker och kräver inte generell åtkomst till hela bildbiblioteket.

Föremålsuppgifter och bildfiler sparas lokalt i appens dokumentkatalog. Ingen molnsynkronisering är implementerad.

## Kvalitetsprinciper
1. AI-förslag får aldrig presenteras som verifierade fakta.
2. Begärt pris, auktionsvärdering och faktiskt slutpris ska hållas isär.
3. Värderingar ska visa källor, datum och jämförbarhet.
4. Osäkerhet ska visas tydligt.
5. Föremålets skick, proveniens och eventuella renoveringar ska vägas in.

## Byggstatus
Detta repo innehåller SwiftUI-källkod. Ett komplett Xcode-projekt, signering och IPA-export återstår. Källändringarna är ännu inte verifierade genom en Xcode-build. Rekommenderad bas är iOS 17 eller senare.
