# ProcureFinder

SwiftUI (iOS 16+), MVVM, async/await. Live-Suche in EU-Ausschreibungen via **TED Search API** (anonym). CPV-Multiselect, Paginierung, Favoriten (Core Data), i18n (de/en via `L10n`), A11y, Dark/Light.

## Architektur
- **Networking**: `TedClient` ruft `POST /v3/notices/search` mit Expert-Query auf; defensive Decodierung.
- **Direktlinks**: HTML/PDF per offiziellem Schema `https://ted.europa.eu/{lang}/notice/{publication-number}/{format}`.
- **CPV**: eingebettetes `Resources/cpv.json` (DE/EN, Main-Vocabulary-Top-Level). Suche & Favoriten.
- **Persistenz**: Core Data (programmatisches Modell) für Offline-Cache & Favoriten-Flag.
- **Pagination**: serverseitig via `page` + `limit`, endloses Scrollen.
- **Caching**: ETag/If-None-Match vorbereitet für GET (aktuell Links werden in Safari geöffnet).
- **Tests**: ≥10 Unit-Tests, 1 UI-Smoke-Test.

## Build mit Codemagic
1. Repo verbinden. Workflow: `ios_release`.
2. **Signatur-Varianten**  
   **A) Manuell (Variablen in Codemagic UI):**
   - `CM_CERTIFICATE` – Base64 P12
   - `CM_CERTIFICATE_PASSWORD`
   - `CM_PROVISIONING_PROFILE` – Base64 `.mobileprovision`
   **B) App Store Connect (alternativ):**
   - `APP_STORE_CONNECT_ISSUER_ID`, `APP_STORE_CONNECT_KEY_IDENTIFIER`, `APP_STORE_CONNECT_PRIVATE_KEY` (falls verwendet – Workflow kann leicht erweitert werden).
3. Icons werden im CI aus einer generierten 1024×1024-Grundgrafik via `sips` in alle Größen abgeleitet.
4. Artefakte: `build/ipa/*.ipa`, `.xcarchive`, `xcodebuild.log`.

## Sideloadly-Installation (Windows/macOS)
1. `.ipa` aus Codemagic-Artefakten laden.
2. In Sideloadly `.ipa` wählen, Apple‑ID (kostenloses Dev‑Konto) angeben.
3. Re-signieren lassen und auf das iPhone installieren.

## API-Referenzen (offiziell)
- TED Developer Docs – **Search API** (anonym, `POST /v3/notices/search`), Swagger: `https://docs.ted.europa.eu/api/latest/search.html` ; UI: `https://ted.europa.eu/api/documentation/index.html`
- Direkte Links zu Notices (HTML/PDF/XML): `https://ted.europa.eu/{lang}/notice/{publication-number}/{format}` (z. B. `html`, `pdf`, `pdfs`, `xml`): `https://ted.europa.eu/en/simap/developers-corner-for-reusers`
- CPV (Main Vocabulary): Überblick & Codelists: `https://ted.europa.eu/en/simap/cpv`

## Screenshots-Hinweise
- Nach dem ersten Start im Simulator/Device: Filter setzen, CPV auswählen, Suche starten; dann Liste/Detail screen-grabben (Light/Dark).

## Pfade
- Quellen: `ProcureFinder/Sources/...`
- Ressourcen: `ProcureFinder/Resources/...`
- Tests: `ProcureFinderTests/*`, `ProcureFinderUITests/*`

## Lizenz
MIT
