# MIKIWA – Produktbeschreibung

> Stand: 2026-05-02 · Version: 1.0 (Initial)

## 1. Vision

MIKIWA ist eine digitale Verwaltungs- und Kommunikationsplattform für **einen** Kindergarten. Sie verbindet Betreuer und Eltern in einer **vertrauensvollen, sicheren und einfachen** Umgebung und ersetzt Zettelwirtschaft, WhatsApp-Gruppen und unstrukturierte E-Mail-Verteiler durch strukturierte, datenschutzkonforme Workflows.

Die obersten Produktprinzipien sind:

1. **Security by Design** – jede Funktion wird unter dem Primat der Datensicherheit entworfen. Es geht um Daten von Kindern.
2. **Privacy by Design** – DSGVO-konforme Datenminimierung, Foto-Einwilligungen, EU-Hosting (AT/DE).
3. **Niemals Datenleck nach außen** – sämtliche Inhalte sind ausschließlich für authentifizierte, berechtigte Benutzer sichtbar.
4. **Selbsterklärende UX** – insbesondere Eltern müssen sich nach Sekunden zurechtfinden.
5. **Mobile-first** – die Plattform wird primär am Smartphone genutzt (PWA).
6. **Rails-Idiomatik** – Umsetzung folgt Rails 8.1 Best Practices.

## 2. Rahmenbedingungen

| Bereich | Festlegung |
|---|---|
| Mandantenmodell | Single-Tenant (genau ein Kindergarten pro Installation) |
| Skalierung | 1–3 Gruppen, ~20 Kinder pro Gruppe |
| Plattform | Web-App, PWA, mobile-first, Browser-optimiert |
| Hosting | Eigener Root-Server in EU (AT/DE), Kamal-Deployment |
| Sprache | Deutsch (Sie-Form gegenüber Eltern) |
| Mehrsprachigkeit | Nicht in v1 (i18n technisch vorbereiten, aber nur DE-Pakete) |
| Externe API | Keine – geschlossenes System |
| Tech-Stack | Ruby on Rails 8.1, Hotwire, ActiveStorage, Solid Queue/Cache/Cable |
| Branding | Komplett aus dem `mikiwa-design`-Skill |

## 3. Zielgruppen & Rollen

| Rolle | Hauptaufgaben |
|---|---|
| **Administrator** | Verwaltet Betreuer- und Admin-Accounts, sperrt/löscht Benutzer aller Typen, konfiguriert das System (Mailer, Branding, Standards). |
| **Betreuer** | Operative Verwaltung: Gruppen, Kindergartenjahre, Kinder, Eltern-Accounts, Veranstaltungen, Listen, Galerien, Mitteilungen, Speiseplan. |
| **Eltern** | Konsumieren Informationen, tragen sich in Listen ein, stimmen ab, pflegen eigene Profil-, Notfall- und Einwilligungsdaten. |

### Berechtigungsmatrix (Auszug)

| Aktion | Admin | Betreuer | Eltern |
|---|:-:|:-:|:-:|
| Betreuer/Admins anlegen, sperren, löschen | ✅ | – | – |
| Eltern anlegen, sperren, löschen | ✅ | ✅ | – |
| Kinder anlegen, Gruppen zuordnen | – | ✅ | – |
| Gruppen verwalten | ✅ | ✅ | – |
| Kindergartenjahre verwalten | ✅ | ✅ | – |
| Veranstaltungen, Listen, Galerien, Mitteilungen, Speiseplan | – | ✅ | – |
| Notfallkontakte/Medizin pflegen (eigenes Kind) | – | ✅ | ✅ |
| Foto-Einwilligung pflegen (eigenes Kind) | – | ✅ | ✅ |
| Listen ausfüllen, Abstimmungen, Galerien einsehen | – | ✅ | ✅ |
| Eigenes Profil pflegen | ✅ | ✅ | ✅ |

---

# Teil A – Technische Features (Foundation)

Die folgenden Features bilden die technische Grundlage. Sie sind Voraussetzung für alle funktionalen Features und werden zuerst umgesetzt.

## T1 – Authentifizierung & Session-Management

**Beschreibung**
Zwei klar getrennte Authentifizierungsverfahren: Passwort-basiert für Betreuer/Admins, Magic-Link-basiert für Eltern.

**Details**
- **Betreuer / Admin**: klassischer Login mit E-Mail + Passwort. Mindestlänge 16 Zeichen, kein Sonderzeichen-Zwang (Stärke kommt aus Länge). Passwort-Reset über zeitlich begrenzten Token-Link (`PasswordsController`). Vorbereitet für TOTP-2FA in einer Folgeversion (nicht v1).
- **Eltern**: ausschließlich Magic Link – kein Passwort vorhanden. Eltern geben ihre E-Mail ein, erhalten einen einmaligen Link mit signiertem, zeitlich begrenztem Token (z.B. 30 Min Gültigkeit), der eine Session öffnet.
- **Initiale Einladung** (Eltern) ist ein erweiterter Magic Link, der den Account aktiviert und das Profil zur Vervollständigung anbietet.
- **Session-Lifetime**: 7 Tage (Eltern und Betreuer). Logout möglich, Cookie `httpOnly`, `Secure`, `SameSite=Lax`.
- **Bruteforce-Schutz**: Rate-Limiting auf Login- und Magic-Link-Endpunkten (Rack::Attack), Account-Lockout nach n Fehlversuchen.
- **Passwort-Hashing**: Rails-Standard `has_secure_password` (bcrypt).

**Abhängigkeiten**: Mailer (T7).

## T2 – Rollen- und Berechtigungssystem

**Beschreibung**
Drei feste Rollen (`admin`, `caretaker`, `parent`). Authorisierung erfolgt zentral, kein Frontend-Trust. Eltern können nur Daten sehen, die zu ihren eigenen Kindern gehören.

**Details**
- Authorisierung über eine Pundit-ähnliche Schicht (oder schlanke selbstgebaute Policy-Klassen, falls Pundit zu schwer wirkt) – pro Ressource ein Policy-Objekt.
- **Scoping** ist kritisch: Eltern-Listen werden serverseitig immer auf die zugeordneten Kinder/Gruppen eingeschränkt – nie clientseitig gefiltert.
- Rollen sind exklusiv (ein Benutzer hat genau eine Rolle).
- Entwickler-Konvention: jede neue Controller-Action MUSS eine Policy aufrufen; ein RuboCop-Cop oder Test-Helper überwacht das.

**Abhängigkeiten**: T1.

## T3 – Datenmodell-Grundgerüst & Mandantenkontext

**Beschreibung**
Single-Tenant-Architektur, aber sauberes Trennungs-Konzept:

- **Gruppe** ist die oberste organisatorische Einheit.
- **Kindergartenjahr** ist eine zeitliche Klammer mit frei wählbarem Start-/Enddatum, an der alle inhaltlichen Entitäten (Veranstaltungen, Galerien, Listen, Speiseplan, Mitteilungen) hängen.
- **Aktives Jahr**: zu jedem Zeitpunkt ist genau ein Kindergartenjahr „aktiv" – das ist der Default-Kontext für Betreuer und Eltern.

**Details**
- Datenbank: SQLite.
- UUIDs als Primärschlüssel für alle benutzerexponierten Ressourcen (verhindert ID-Enumeration in URLs).
- `created_at` / `updated_at` immer mitführen.

**Abhängigkeiten**: keine.

## T4 – Privacy & DSGVO-Grundlagen

**Beschreibung**
Datenschutz wird als Querschnittsthema technisch verankert.

**Details**
- **Datenstandort**: ausschließlich EU (AT/DE), inkl. ActiveStorage und Backups.
- **TLS**: erzwungen (HSTS), HTTPS-only.
- **Verschlüsselung**: sensible Felder (Notfallkontakte, medizinische Hinweise) werden mit `ActiveRecord::Encryption` at-rest verschlüsselt.
- **Backups**: tägliche, verschlüsselte DB- und Storage-Backups, automatische Rotation (z.B. 14 Tage).
- **Logs**: keine PII in Logs (E-Mail, Tokens, Passwörter herausfiltern, Rails 8 `filter_parameters`).
- **Cookie-Banner**: nicht erforderlich – ausschließlich technisch notwendige Cookies.
- **Datenschutzerklärung & Impressum**: statische Seiten (siehe F1.5).
- **Kein Audit-Log** in v1.
- **Kein automatisches Löschen** in v1 (manuelle Datenpflege durch Betreuer).

**Abhängigkeiten**: T3, T9.

## T5 – PWA & Mobile-first UX-Foundation

**Beschreibung**
Die App wird als Progressive Web App ausgeliefert, optimiert für Smartphone-Nutzung.

**Details**
- **Manifest** mit App-Name, Icons (verschiedene Größen), Theme-Color, Start-URL.
- **Installierbar** auf Home-Screen (iOS/Android), Standalone-Display.
- **Service Worker** liefert App-Shell ausgeliefert (kein Offline-Inhalt in v1, aber Offline-Fallback-Seite).
- **Responsive Layout**: Mobile-first mit Tailwind-CSS, Breakpoints sm/md/lg/xl.
- **Touch-Targets** ≥ 44 px.
- **Hotwire (Turbo + Stimulus)** für reaktive UI ohne SPA-Komplexität.
- **Design**: alle Komponenten und Tokens aus dem `mikiwa-design`-Skill.

**Abhängigkeiten**: keine.

## T6 – Bild- und Datei-Pipeline

**Beschreibung**
ActiveStorage-basiert, mit automatischer Bildoptimierung und Größenbegrenzung.

**Details**
- **Storage-Backend**: lokal auf dem Root-Server (per Volume), strukturiert nach Kindergartenjahr/Galerie. Keine externen Cloud-Storages in v1.
- **Bildoptimierung**: automatische Komprimierung beim Upload (z.B. via `image_processing` mit libvips), generierte Varianten:
  - `thumb` (300 px lange Kante, WebP)
  - `display` (1600 px lange Kante, WebP, qualitätsoptimiert)
  - `original` (für Download durch Betreuer/Eltern, max. 4000 px lange Kante)
- **Größenbegrenzung pro Upload**: 15 MB.
- **Limit pro Galerie**: 200 Bilder (sanftes Limit, konfigurierbar).
- **Erlaubte Formate**: JPEG, PNG, HEIC, WebP. PDF nur, wo explizit benötigt.
- **EXIF-Daten** werden beim Upload entfernt (Privacy: keine GPS-/Gerätedaten).
- **Auslieferung**: signierte, kurzlebige URLs (kein direkter Public-Read-Zugriff).

**Abhängigkeiten**: T4.

## T7 – Mailer & E-Mail-Pipeline

**Beschreibung**
Zuverlässiger transaktionaler und Massen-E-Mail-Versand.

**Details**
- **Provider**: ein DSGVO-konformer EU-Mailprovider => Mailjet
- **Transactional**: Magic Links, Passwort-Reset, Einladungen, Mitteilungs-Benachrichtigungen.
- **Massen-Mails**: Mitteilungen an mehrere Eltern werden über ActiveJob (Solid Queue) parallelisiert versendet, mit Retry-Strategie.
- **Mailer-Layouts**: HTML + Text-Variante, Branding aus `mikiwa-design`-Skill.
- **Bounces & Beschwerden**: Provider-Webhook deaktiviert nicht zustellbare Adressen automatisch und markiert Eltern-Account als „E-Mail ungültig".
- **Test-Modus**: Letter Opener im Development.

**Abhängigkeiten**: T1, T2.

## T8 – iCal-Feed (Kalender-Abonnement)

**Beschreibung**
Jeder Benutzer kann den persönlichen Kalender via iCal/.ics-Feed abonnieren.

**Details**
- Pro Benutzer eine **personalisierte, signierte URL** (`/calendar/<token>.ics`), die bei Bedarf rotiert werden kann.
- Inhalt sind alle Kalenderereignisse + Veranstaltungen, die für den Benutzer sichtbar sind (Eltern: nur Inhalte aus Gruppen ihrer Kinder; Betreuer/Admin: alles).
- Kompatibel mit Apple Kalender, Google Kalender, Outlook.
- HTTP-Caching mit `Last-Modified`/`ETag`, kein zwingendes Auth-Cookie (Token in der URL ist die Auth).
- Nicht in Suchmaschinen indexierbar (`X-Robots-Tag: noindex`).

**Abhängigkeiten**: T1, T11, F6, F7.

## T9 – Hosting, Deployment & Operations

**Beschreibung**
Self-hosted auf eigenem Root-Server in der EU, Deployment via Kamal.

**Details**
- **Server**: 1 Root-Server (EU/DE oder EU/AT), aktuelle Linux-Distribution.
- **Container**: Kamal-managed Docker-Container (Rails-App, SQLite, optional Caddy/Traefik als Reverse-Proxy mit automatischem Let's Encrypt).
- **Background-Jobs**: Solid Queue (in v1 keine separate Worker-VM nötig).
- **Cache & Cable**: Solid Cache, Solid Cable.
- **Backups**: nightly DB-Dumps + ActiveStorage-Volume-Snapshot, verschlüsselt, in zweiter EU-Region.
- **Monitoring**: einfache Health-Checks (`/up`), optional Sentry oder selbst-gehostetes GlitchTip für Errors.
- **Zero-Downtime-Deployment**: Kamal Standard-Workflow.
- **Secrets**: Rails Encrypted Credentials, kein Secret im Repo.

**Abhängigkeiten**: T4.

## T10 – Test-Foundation

**Beschreibung**
Alle wesentlichen Features werden mit Unit- und System-Tests abgesichert (User-Anforderung).

**Details**
- **Unit-Tests** (Minitest, Rails-Standard): Models, Policies, Mailers, Services.
- **System-Tests** (Capybara + Selenium/Headless Chrome): kritische End-to-End-Flows
  - Login (Passwort + Magic Link)
  - Kind anlegen + Eltern einladen
  - Veranstaltung anlegen, Liste füllen, Galerie hochladen
  - Eltern: Posteingang, Liste eintragen, Galerie ansehen
- **Coverage**: SimpleCov, Ziel ≥ 85 % Lines auf Application Code.
- **CI**: GitHub Actions (oder selbst gehosteter Runner), Tests + RuboCop + Brakeman bei jedem Push.
- **Brakeman & Bundler-Audit** als Security-Linter im CI-Pipeline.

**Abhängigkeiten**: alle anderen T-Features (T1–T9, T11).

## T11 – Sicherheits-Härtung & Anti-Leak-Maßnahmen

**Beschreibung**
Konkrete Maßnahmen, um das oberste Prinzip „niemals Daten an Externe leaken" zu erfüllen.

**Details**
- **Robots**: gesamte Anwendung mit `X-Robots-Tag: noindex, nofollow` ausgeliefert (außer Login/öffentliche statische Seiten).
- **CSP** (Content-Security-Policy) restriktiv: nur eigene Origins, kein Inline-JS außer mit Nonces, kein externer Tracking-Code.
- **CSRF**: Rails-Standard, Forme-Tokens überall erzwungen.
- **CORS**: standardmäßig deaktiviert (kein API-Zugriff von außen).
- **Bilder/Galerie-URLs**: ausschließlich signiert, kurzlebig, kein direktes Bucket-Public-Listing.
- **iCal-Feed-Tokens**: rotierbar.
- **Login-Seite und Magic-Link-Seite** geben **keine Information** preis, ob eine E-Mail-Adresse existiert oder nicht (gegen Enumeration).
- **Magic-Link-Tokens** sind Single-Use, kurz gültig, und werden nach Verbrauch invalidiert.

**Abhängigkeiten**: T1, T2, T4, T5, T6, T7. (T8 baut auf T11 auf, nicht umgekehrt – T8 ist in Phase 3 und nutzt die hier definierten Sicherheitsmaßnahmen.)

---

# Teil B – Funktionale Features

Die funktionalen Features setzen auf der technischen Grundlage auf. Reihenfolge spiegelt eine sinnvolle Implementierungsreihenfolge wider, ist aber keine harte Vorgabe.

## F1 – Benutzer- und Systemverwaltung (Admin-Bereich)

**Beschreibung**
Zentrale Verwaltung aller Betreuer-/Admin-Accounts und der globalen System-Einstellungen.

**Funktionen**
- Liste aller Betreuer + Admins, mit Status (aktiv/gesperrt).
- Anlegen, Sperren, Reaktivieren, Löschen von Betreuer- und Admin-Accounts.
- Sperren/Löschen jedes Eltern-Accounts (auch wenn von Betreuern angelegt).
- Globale System-Konfiguration: Mailer-Einstellungen, Default-Branding-Werte, Standard-Texte (z.B. Einladungs-Template).
- Statische Seiten **Impressum** und **Datenschutzerklärung** pflegen (durch Admin im UI editierbar oder als Markdown-Dateien deploybar).

**User-Stories (Auszug)**
- Als Admin will ich eine neue Betreuerin per E-Mail einladen, damit sie ihr Passwort selbst setzen kann.
- Als Admin will ich einen kompromittierten Account sofort sperren können.

**Abhängigkeiten**: T1, T2.

## F2 – Gruppen- und Kindergartenjahr-Verwaltung

**Beschreibung**
Verwaltung der 1–3 Gruppen und der Kindergartenjahre als zeitliche Klammer.

**Funktionen**
- Gruppe anlegen: Name, optionale Farbe (für UI-Akzent), optionale Kurzbeschreibung.
- Kindergartenjahr anlegen: Bezeichnung („KGJ 2026/27"), Start- und Enddatum (frei wählbar).
- **Genau ein** Jahr ist „aktiv" (Default-Kontext); Wechsel des aktiven Jahres durch Betreuer/Admin.
- **Jahresübergang** (vereinfacht):
  - Neues Jahr anlegen.
  - Im Massen-Dialog: Liste aller Kinder des Vorjahres mit Checkboxen → ausgewählte Kinder werden ins neue Jahr übernommen.
  - **Notfallkontakte, medizinische Hinweise und Foto-Einwilligungen** der übernommenen Kinder werden automatisch ins neue Jahr kopiert.
  - **Speiseplan, Veranstaltungen, Listen, Galerien, Mitteilungen** werden NICHT übernommen, das neue Jahr startet inhaltlich leer.
- **Sichtbarkeit vergangener Jahre**:
  - Eltern sehen alle Jahre, in denen mindestens eines ihrer Kinder einer Gruppe zugeordnet war – und in diesen Jahren uneingeschränkten Zugriff auf Galerien/Veranstaltungen/Speiseplan dieser Gruppen.
  - Betreuer und Admins sehen alle Jahre.

**Abhängigkeiten**: T2, T3.

## F3 – Kinder-Stammdaten

**Beschreibung**
Pflege der Kinder, ihrer Gruppen-Zuordnung und ihrer kindspezifischen Daten.

**Pflichtfelder**
- Vorname, Nachname
- Geburtsdatum
- Zugeordnete Gruppe (innerhalb des aktuellen Kindergartenjahres)
- Mindestens 1 Erziehungsberechtigte:r
- Foto-Einwilligung (Boolean ja/nein)

**Optionale Felder**
- Profilfoto (von Eltern oder Betreuern hochladbar; sichtbar für alle authentifizierten Benutzer der Plattform – nicht öffentlich)
- Spitzname / Rufname

**Funktionen**
- Anlegen, bearbeiten, deaktivieren (z.B. „verlassen", nicht löschen).
- Beim Anlegen können bestehende Eltern-Accounts zugeordnet ODER neue Eltern direkt mit angelegt + eingeladen werden.
- Pro Kind-Eltern-Zuordnung: ein **Freitext-Bemerkungsfeld** (z.B. „Mutter, Hauptansprechpartnerin", „Großvater, holt mittwochs ab").
- Geschwister: ein Eltern-Account kann mehreren Kindern zugeordnet sein, auch über mehrere Gruppen hinweg – Eltern sehen die Inhalte aller Gruppen ihrer Kinder.

**Abhängigkeiten**: T2, T3, F2, F4.

## F4 – Eltern-Account-Verwaltung & Onboarding

**Beschreibung**
Eltern werden ausschließlich von Betreuern angelegt und per E-Mail eingeladen.

**Funktionen**
- Anlage eines Eltern-Accounts: E-Mail (Pflicht), Vorname, Nachname, Telefonnummer (optional, für Notfallkontakt-Verwendung).
- Beim Speichern: automatische Versand-E-Mail mit **initialer Magic-Link-Einladung** und kurzer Begrüßungstext.
- Ein Eltern-Account kann mehreren Kindern zugeordnet werden (Geschwister-Logik in F3).
- Eltern bearbeiten ihr eigenes Profil (Name, Telefon, E-Mail), aber nicht ihre Kind-Zuordnung.
- Betreuer können einen Eltern-Account deaktivieren (z.B. wenn das Kind den Kindergarten verlässt) oder eine neue Magic-Link-Einladung erneut versenden.

**Abhängigkeiten**: T1, T2, T7, F3.

## F5 – Notfallkontakte & medizinische Hinweise

**Beschreibung**
Pro Kind hinterlegte sicherheitsrelevante Daten, die im Ernstfall sofort zugreifbar sind.

**Datenmodell pro Kind**
- **Notfallkontakte** (n Stück): Name, Beziehung zum Kind (Freitext), Telefon, Reihenfolge.
- **Medizinische Hinweise**: Allergien, Medikamente, Besonderheiten (Freitext, mehrere Einträge).
- **Versicherung** (optional): Krankenkasse, Versicherungsnummer.

**Funktionen**
- Eltern pflegen die Daten ihres Kindes selbst.
- Betreuer können einsehen und bearbeiten (für alle Kinder).
- Alle anderen Eltern haben **keinen** Einblick in fremde Notfallkontakte.
- **Verschlüsselung at-rest** (siehe T4) für medizinische Felder und Versicherungsnummer.
- Übernahme ins neue Kindergartenjahr automatisch, wenn das Kind übernommen wird (siehe F2).

**Abhängigkeiten**: T2, T4, F3.

## F6 – Kalender & Kalenderereignisse

**Beschreibung**
Zentrale Übersicht aller Termine, Veranstaltungen, Sperrtage.

**Funktionen**
- Kalender-Ansicht: Monat / Liste, Filter nach Gruppe, Filter nach Kindergartenjahr.
- **Kalenderereignis** (einfach): Titel, Datum (ganztägig oder mit Uhrzeit), optionaler Ort, Beschreibung, betroffene Gruppen (1..n).
- **Veranstaltung** (siehe F7) wird ebenfalls im Kalender angezeigt, optisch differenziert (z.B. Akzentfarbe).
- **iCal-Abo**: jeder Benutzer findet im Profil seinen persönlichen Abo-Link inkl. Anleitung für iOS/Android (siehe T8).
- Eltern sehen ausschließlich Ereignisse von Gruppen, in denen mindestens eines ihrer Kinder ist (im jeweiligen Jahr).

**Abhängigkeiten**: T2, T3, T8, F2.

## F7 – Veranstaltungen

**Beschreibung**
Eine Veranstaltung ist ein Kalenderereignis mit erweiterten Inhalten.

**Datenmodell**
- Titel, Datum/Uhrzeit, Ort, Beschreibung
- Zugeordnete Gruppen (1..n)
- Optional verknüpfte:
  - **Teilnahmeliste** (max. 1, siehe F8)
  - **Einkaufsliste** (max. 1, siehe F9)
  - **Bildergalerie** (genau 1, siehe F11) – wird typischerweise nach der Veranstaltung gefüllt
- Optional verknüpfte Abstimmung (max. 1, siehe F10) – z.B. Terminumfrage zur Vorbereitung

**Funktionen**
- Anlegen, bearbeiten, absagen, löschen (durch Betreuer).
- Eltern sehen Detailseite mit allen verknüpften Inhalten in einer aufgeräumten Ansicht.
- Eltern können von der Veranstaltungs-Detailseite direkt zur Teilnahme/Liste/Abstimmung springen.
- **Implementierungshinweis**: Die Kernfunktion (Veranstaltung anlegen/verwalten/absagen) ist unabhängig von F8–F11 implementierbar; die Modulverknüpfungen werden schrittweise im Zuge der jeweiligen Feature-Implementierung ergänzt.

**Abhängigkeiten**: F6 (Verknüpfungen zu F8, F9, F10, F11 werden schrittweise ergänzt).

## F8 – Teilnahmelisten

**Beschreibung**
Einfache Listen, in die sich Eltern eintragen.

**Funktionen**
- Liste hat: Titel, optionale Beschreibung, optionalen Anmeldeschluss, optionales **fixes Datum** ODER **mehrere Datums-Optionen** (Doodle-artig).
- Eintragsmodi:
  - **Allgemein** (1 Spalte „Ich/mein Kind kommt"): Eltern setzen Häkchen.
  - **Pro Datum**: Eltern setzen Häkchen pro angebotenem Datum.
- Eltern können sich pro Kind eintragen (relevant bei Geschwistern in derselben Gruppe).
- Liste zeigt namentlich, wer sich wann eingetragen hat (sichtbar für Betreuer und alle Eltern der Gruppe).
- Eltern können ihren Eintrag wieder zurücknehmen, solange Anmeldeschluss nicht überschritten.
- Betreuer können Listen exportieren (CSV) für die Offline-Vorbereitung.

**Abhängigkeiten**: T2, F2, F3.

## F9 – Einkaufslisten

**Beschreibung**
Aktive Unterstützung beim Einkaufen für eine Veranstaltung.

**Funktionen**
- Einkaufsliste hat: Titel, **fixes Datum** (Bezugstag der Veranstaltung), optionale Beschreibung, n Positions-Einträge.
- Eintrag: Bezeichnung (z.B. „2 kg Mehl"), optional Menge, optional Bemerkung.
- **Erledigt-Status** pro Eintrag: Eltern oder Betreuer können einen Eintrag abhaken („erledigt" mit Zeitstempel + Person, persistent gespeichert).
- Wieder-Aufheben des Status möglich.
- **Mobile-optimierte Ansicht**: große Touch-Targets, optimiert für die Verwendung **während des Einkaufens** (z.B. Großschrift, Filter „nur offen", Haptik-Feedback).
- Anzeige: wer hat was erledigt (sichtbar für alle Beteiligten).

**Abhängigkeiten**: T2, T5, F2.

## F10 – Abstimmungen

**Beschreibung**
Namentliche Abstimmungen zu Fragen oder Terminen.

**Funktionen**
- Abstimmung hat: Frage/Titel, Beschreibung, Optionen (n Stück), Typ:
  - **Einfachauswahl** – genau eine Option
  - **Mehrfachauswahl** – beliebige Anzahl
- Optional: Stimmschluss-Datum, danach keine Änderungen mehr möglich.
- **Namentlich**: das Ergebnis zeigt, wer wofür gestimmt hat.
- Betreuer können Abstimmung schließen, archivieren, Ergebnis exportieren (CSV).
- Eltern können ihre Stimme ändern, solange offen.
- Abstimmungen können optional an eine Veranstaltung gekoppelt werden (siehe F7).

**Abhängigkeiten**: T2, F2.

## F11 – Bildergalerien

**Beschreibung**
Galerien zur Dokumentation des Kindergarten-Alltags und von Veranstaltungen.

**Funktionen**
- Galerie hat: Titel, Beschreibung, zugeordnete Gruppe(n), Datum/Zeitraum, optionale Verknüpfung zu einer Veranstaltung.
- Mehrfach-Upload, Drag & Drop, mit Fortschrittsanzeige.
- Bildoptimierung automatisch (siehe T6).
- Anzeige als Grid-Galerie mit Lightbox.
- **Sichtbarkeit**: alle Eltern der zugeordneten Gruppe(n) sehen alle Bilder der Galerie.
- **Foto-Einwilligungs-Hinweis**: beim Anlegen/Hochladen erscheint ein Hinweis, welche Kinder der Gruppe **keine** Foto-Einwilligung haben (Liste mit Namen) – Betreuer ist verantwortlich für die manuelle Vorauswahl. Keine automatische Bilderkennung in v1.
- Bilder können von Eltern/Betreuern in voller Auflösung heruntergeladen werden (signierte URL).
- Betreuer können Galerien bearbeiten und einzelne Bilder nachträglich entfernen.

**Abhängigkeiten**: T2, T6, F2.

## F12 – Mitteilungen / digitaler Posteingang

**Beschreibung**
Strukturierte einseitige Kommunikation Betreuer → Eltern, mit persistenter Archivierung im System.

**Funktionen**
- Betreuer verfasst Mitteilung: Titel, Inhalt (Rich-Text), zugeordnete Gruppe(n) ODER explizite Empfängerliste (z.B. nur Eltern bestimmter Kinder), optional Anhang (z.B. PDF).
- Beim Versenden:
  - Mitteilung wird im **digitalen Posteingang** der Empfänger gespeichert.
  - Zusätzlich wird eine **E-Mail-Benachrichtigung** mit Inhalt + Tiefenlink in den Posteingang versandt.
- Eltern sehen einen Posteingang mit:
  - ungelesen / gelesen
  - Filter nach Datum, Gruppe
  - Detailansicht
- **Keine Antwortfunktion** in v1 (einseitige Kommunikation).
- **Keine Eltern-zu-Eltern-Kommunikation** in v1.
- Betreuer haben einen „Gesendet"-Bereich und können Mitteilungen archivieren.

**Abhängigkeiten**: T2, T7.

## F13 – Speiseplan

**Beschreibung**
Optionaler Speiseplan pro Gruppe, wochenweise geplant von Betreuern (meist die Vorwoche) als reine Leseübersicht für Eltern.

**Funktionen**
- Planung erfolgt **wochenweise**: Betreuer füllen die Einträge einer Woche (Mo–Fr), typischerweise die Woche zuvor.
- Speiseplan-Eintrag pro Tag: Datum, Gruppe(n), Speise (Freitext), Allergie-/Hinweistext (Freitext, z.B. „enthält Gluten, Laktose").
- **Primäre und einzige Ansicht: Wochenansicht** – navigierbar (zurück / vor), Standard ist die aktuelle Woche.
- Betreuer können zukünftige Wochen vorausplanen (Einträge anlegen, bearbeiten, löschen).
- Eltern sehen den Speiseplan ihrer Kinder-Gruppe im **Lesemodus** – wochenweise navigierbar.
- Speiseplan ist **nicht** an ein einzelnes Kind gebunden, sondern an die Gruppe.
- Wird **nicht** in das nächste Kindergartenjahr übernommen.

**Abhängigkeiten**: T2, F2.

## F14 – Geburtstagsübersicht

**Beschreibung**
Übersicht aller Geburtstage in einer Gruppe.

**Funktionen**
- Pro Gruppe eine Liste aller Kinder mit ihren Geburtstagen, sortierbar nach Datum (Jahresansicht) oder Alter.
- Hervorhebung **anstehender Geburtstage** (z.B. nächste 14 Tage) auf dem Eltern-Dashboard.
- Sichtbar für alle Eltern derselben Gruppe und für Betreuer.

**Abhängigkeiten**: T2, F3.

## F15 – Foto-Einwilligungsverwaltung

**Beschreibung**
Pro Kind dokumentierte Einwilligung, ob das Kind auf Bildern erscheinen darf.

**Funktionen**
- Boolean-Flag „Foto-Einwilligung erteilt: ja/nein" am Kind-Profil, mit Zeitstempel der letzten Änderung.
- Pflegbar durch Eltern und Betreuer.
- Beim Anlegen einer Bildergalerie/Upload zeigt das System eine Liste der Kinder **ohne Einwilligung** in der betroffenen Gruppe als Hinweis (siehe F11).
- Übernahme ins neue Kindergartenjahr automatisch (siehe F2).
- Keine harte Sperre durch das System – die Verantwortung liegt beim Betreuer (bewusste Vereinfachung).

**Abhängigkeiten**: T2, F3, F11.

## F16 – WhatsApp-Share-Links

**Beschreibung**
Niederschwellige Möglichkeit, Inhalte mit Eltern außerhalb von MIKIWA zu verbreiten.

**Funktionen**
- Auf den Detailseiten von Veranstaltungen, Listen, Abstimmungen ein „Teilen"-Knopf.
- Der Knopf öffnet einen `https://wa.me/?text=…`-Link mit vorgefertigtem Text + URL.
- Die geteilte URL ist die normale, **authentifizierungspflichtige** Detail-URL – Empfänger landen bei MIKIWA, müssen sich aber wie üblich anmelden.
- Keine WhatsApp-Business-API-Integration in v1.
- Verfügbar für Betreuer und Eltern (für Eltern: nur zu ihren erlaubten Inhalten).

**Abhängigkeiten**: T11.

## F17 – Eltern-Dashboard (Startseite)

**Beschreibung**
Eltern-Startseite, die einen Sekunden-Überblick gibt.

**Funktionen** (Sektionen)
- **Ungelesene Mitteilungen** (Top, falls vorhanden).
- **Anstehende Veranstaltungen** der eigenen Kinder (nächste 14 Tage).
- **Offene Listen / Abstimmungen**, in denen ich noch keine Stimme abgegeben habe.
- **Anstehende Geburtstage** in den Gruppen meiner Kinder.
- **Heute / morgen im Speiseplan** (falls vorhanden).
- Quick-Links: Kalender, Galerien, Profil.

**Designprinzip**: maximal 1 Aktion pro Karte, große Tap-Targets, klare Farbcodes aus dem Mikiwa-Designsystem.

**Abhängigkeiten**: F6, F8, F10, F12, F13, F14.

## F18 – Betreuer-Dashboard

**Beschreibung**
Operative Startseite für Betreuer.

**Funktionen** (Sektionen)
- **Heute**: Veranstaltungen, fälliger Speiseplan, anstehende Geburtstage in den Gruppen.
- **Offene Aufgaben**: Listen ohne genug Eintragungen, Abstimmungen vor Stimmschluss, fehlende Galerien zu vergangenen Veranstaltungen, Kinder ohne Foto-Einwilligungs-Antwort.
- **Schnellaktionen**: neue Mitteilung, neue Veranstaltung, neues Kind anlegen.
- **Statistik (klein)**: Anzahl Kinder pro Gruppe im aktuellen Jahr.

**Abhängigkeiten**: viele (Querschnitt).

---

# Teil C – Roadmap-Hinweise & Out-of-Scope für v1

Bewusst **nicht** in v1 enthalten (auf Basis der Interviews):

- Mandantenfähigkeit / Multi-Kindergarten
- Native iOS-/Android-Apps (PWA reicht)
- Offline-Modus
- 2FA (TOTP)
- SMS-Versand
- WhatsApp Business API
- Eltern-zu-Eltern-Kommunikation
- Antwortfunktion auf Mitteilungen
- Digitale Krankmeldung
- Anwesenheitstracking / Check-in-Check-out
- Dokumenten-Bibliothek
- „Verloren & Gefunden"-Pinnwand
- Erinnerungen für Wechselsachen
- Mehrsprachigkeit
- Bezahlfunktion (Stripe etc.)
- Stimmungsbarometer / anonyme Eltern-Befragungen
- Tagesweise Abhol-Berechtigung
- Audit-Log
- Externe API
- Automatische Lösch-/Aufbewahrungsfristen
- Bilderkennungs-/Gesichts-Blurring

Diese Punkte werden für eine spätere Version offen gehalten und sollen die v1 nicht aufblähen.

---

# Teil D – Glossar

| Begriff | Bedeutung |
|---|---|
| **Gruppe** | Oberste organisatorische Einheit (z.B. „Bären"). |
| **Kindergartenjahr** | Zeitliche Klammer mit frei wählbarem Start-/Enddatum, an der inhaltliche Entitäten hängen. |
| **Aktives Jahr** | Das Kindergartenjahr, das aktuell als Default-Kontext gilt. |
| **Kalenderereignis** | Einfacher Termin im Kalender (z.B. „Kindergarten geschlossen"). |
| **Veranstaltung** | Erweitertes Kalenderereignis mit verknüpften Listen, Galerie, Abstimmung. |
| **Magic Link** | Einmaliger, signierter Link per E-Mail, der ohne Passwort eine Session öffnet. |
| **Mitteilung** | Persistente, einseitige Nachricht von Betreuern an Eltern (mit E-Mail-Versand). |
