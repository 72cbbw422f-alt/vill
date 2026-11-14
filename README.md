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
│   ├── Collection/CollectionView.swift
│   └── Profile/ProfileView.swift
└── Models/
    ├── AntiqueItem.swift
    └── Valuation.swift
```

## Status – grundversion
- [x] SwiftUI-appens startpunkt
- [x] Navigation: Hem, Skanna, Samling och Profil
- [x] Antikt färg- och typografisystem
- [x] Startsida med ingång till skanning
- [x] Välja foto från bildbiblioteket
- [x] Ta foto med enhetens kamera
- [x] Gemensam förhandsvisning för importerade och fotograferade bilder
- [x] Grundmodeller för föremål och värderingsunderlag
- [ ] Bildanalys och AI-identifiering
- [ ] Källbelagd värdering
- [ ] Lokal lagring och samling
- [ ] Xcode-projekt och bygg-/testpipeline

## Integritet och behörigheter
När Xcode-projektet sätts upp måste appens `Info.plist` innehålla `NSCameraUsageDescription` med en tydlig svensk förklaring till varför kameran används. Bildbiblioteket hanteras via PhotosPicker och kräver inte generell åtkomst till hela bildbiblioteket.

## Kvalitetsprinciper
1. AI-förslag får aldrig presenteras som verifierade fakta.
2. Begärt pris, auktionsvärdering och faktiskt slutpris ska hållas isär.
3. Värderingar ska visa källor, datum och jämförbarhet.
4. Osäkerhet ska visas tydligt.
5. Föremålets skick, proveniens och eventuella renoveringar ska vägas in.

## Byggstatus
Detta repo innehåller SwiftUI-källkod. Ett komplett Xcode-projekt, signering och IPA-export återstår. Rekommenderad bas är iOS 17 eller senare.
