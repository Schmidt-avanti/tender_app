# TenderSmartApp (ohne TED Europa)

Diese Version nutzt OpenAI + Websuche (SerpAPI oder Bing Web Search) zur **intelligenten Ausschreibungssuche** und -Extraktion – ganz ohne TED Europa. Läuft mit **Codemagic** und ist für **Sideloadly** geeignet.

## Was ist drin?
- **OpenAIClient**: Chat Completions gegen `gpt-4o-mini` für Query-Expansion & Extraktion
- **SearchProvider**: Adapter (SerpAPI, Bing) + Mock (ohne Keys lauffähig)
- **TenderExtractor**: Lässt OpenAI die Felder aus Seiteninhalt ziehen
- **PageFetcher**: Holt HTML & extrahiert reinen Text (ohne externe Pakete)
- **SearchViewModel**: Orchestriert Suche -> Links -> Text -> strukturierte Tenders
- **SwiftUI UI**: Suche, Trefferliste, Detail, Gebote, Saved Searches, Stats (iOS 16 kompatibel)
- **Sicherheit**: Keys aus Umgebungsvariablen **oder** `AppSecrets.swift`

## API-Keys einsetzen
1. **Schnellstart (lokal / Sideload)**: Öffne `Services/AppSecrets.swift` und trage deinen Key ein:
   ```swift
   return "YOUR_OPENAI_API_KEY"
   ```
   Optional: `SERP_API_KEY` (SerpAPI) oder `BING_API_KEY` (Bing Web Search).  
   > Ohne Key nutzt die App einen Mock-Provider und zeigt Beispiel-Daten.

2. **Codemagic (empfohlen)**: Lege in den Environment Vars an:
   - `OPENAI_API_KEY`
   - `SERP_API_KEY` **oder** `BING_API_KEY`
   Die App liest automatisch zuerst Umgebungsvariablen (`ProcessInfo.processInfo.environment`).

## iOS Berechtigungen / ATS
Damit das Laden fremder Websites klappt, ist in `Info.plist` (siehe `Info.plist.template`) **ATS** locker gesetzt:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key><true/>
</dict>
```
Wenn du deinen bestehenden `Info.plist` behalten willst, **füge obige Keys hinzu**.

## Codemagic
Beispiel `codemagic.yaml` liegt bei. Wichtig:
- **Ohne Signierung** bauen (für Sideloadly), siehe Script.
- Artefakte: `.app` und gezippte `.ipa`.

## Sideloadly
Nimm die erzeugte `.ipa` (oder `.app`) aus den Codemagic-Artefakten und lade sie mit Sideloadly auf dein Gerät.

## Schritt für Schritt Migration in bestehendes Xcode-Projekt
1. **Ordner kopieren/ersetzen** in deinem Repo/Projektverzeichnis:
   - `Models/`
   - `Services/`
   - `ViewModels/`
   - `Views/`
   - `DesignSystem/`
   - `TendersApp.swift`
2. **Info.plist**: Übernimm die ATS-Keys aus `Info.plist.template` (oder nutze die Template-Datei als Ersatz und trage deine Bundle-ID ein).
3. **Build Settings**: Minimum iOS 16.0.
4. **Clean Build Folder** (Shift+Cmd+K) und **Build**.
5. **Test ohne Keys**: Der Mock-Provider liefert Beispieldaten.
6. **Keys setzen** und erneut testen:
   - OpenAI: Pflicht für echte Suche/Extraktion.
   - SerpAPI **oder** Bing: für Websuche (Links).

## Wie funktioniert die Suche?
1. **Query-Expansion** via OpenAI (bessere Schlagworte/CPV-ähnlich).
2. **Websuche** via SerpAPI/Bing → Liste von URLs.
3. **Seiten abrufen** → reinen Text extrahieren.
4. **OpenAI-Extraktion** → strukturierte `Tender`-Objekte (Titel, Käufer, Ort, Frist, Budget, URL, Summary).

## Grenzen / Tipps
- Manche Webseiten blocken Scraper oder laden Content via JS → dann evtl. kein Text.
- Erhöhe `limit` in `SearchViewModel.performSearch()` für mehr Links (kostet Zeit & Tokens).
- Füge weitere Provider hinzu (RSS, proprietäre APIs) durch neue `SearchProvider`-Implementierungen.
- Für produktive Nutzung: Caching & Persistenz ergänzen, Qualität durch Prompts nachschärfen.

Viel Erfolg!