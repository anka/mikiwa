# Deployment-Plan: Mikiwa auf mentalflares

Strukturierter, abarbeitbarer Plan für das initiale Production-Deployment der Rails-App
auf dem bestehenden Server `mentalflares` (Ubuntu 22.04, DigitalOcean).

**Statusführung**: Jeden Schritt nach Abschluss mit `[x]` markieren. Bei Abweichungen vom
Plan einen kurzen Vermerk unter dem Schritt ergänzen.

**Quellinformationen**: Server-Bestandsaufnahme, Konventionen und Betriebs-Cheatsheet liegen
in [`docs/deployment.md`](./deployment.md). Bei jeder Änderung dort den Stand pflegen.

---

## Phase 1 — Repo-Anpassungen (lokal)

- [x] **1.1** `config/environments/production.rb` patchen
  - `config.assume_ssl = true` aktiviert (nginx terminiert SSL)
  - `config.hosts << "app.mikiwa.at"` (DNS-Rebinding-Schutz)
  - Logger auf `Rails.root.join("log/production.log")` umgestellt, TaggedLogging behalten
  - `silence_healthcheck_path` und `force_ssl` unverändert
- [x] **1.2** `bin/docker-entrypoint`: `db:prepare`-Block entfernt — Entrypoint reicht
  jetzt nur noch durch (`exec "${@}"`). Migration übernimmt der `migrate`-Service.
- [x] **1.3** `Dockerfile`: `procps` zu den Base-Packages hinzugefügt — `pgrep` wird vom
  Worker-Healthcheck gebraucht. (`ruby:slim` enthält es nicht standardmäßig.)
- [x] **1.4** `.github/workflows/docker-publish.yml` angelegt
  - Trigger: Push auf `main` + `workflow_dispatch`
  - Build via `docker/build-push-action@v6`, Plattform `linux/amd64`
  - Push als `ghcr.io/anka/mikiwa:latest` **und** `ghcr.io/anka/mikiwa:sha-<short>`
  - Cache: GHA-Cache (`type=gha`)
  - Auth: `GITHUB_TOKEN` mit `packages: write`
- [x] **1.5** Compose-Dateien & Server-Artefakte unter `deploy/` angelegt
  - `deploy/docker-compose.yml` — Services `migrate`, `web` (Port 8080), `worker`
  - `deploy/.env.example` — alle erforderlichen Variablen mit Kommentaren
  - `deploy/nginx/app.mikiwa.at.conf` — vhost (HTTP-Block; certbot ergänzt SSL)
  - `deploy/logrotate/mikiwa` — Logrotate-Snippet mit `copytruncate`
  - `deploy/scripts/backup.sh` — SQLite-Online-Backup, 14 Tage Retention
  - `deploy/cron/mikiwa-backup` — Cron 03:00 daily
- [x] **1.6** `docs/deployment.md` und `AGENTS.md` gepflegt (Verweise + Inventar)
- [ ] **1.7** Branch `feature/server-deployment` (oder vergleichbar) anlegen, Änderungen
  committen, PR gegen `main` öffnen. **Merge erst nach lokaler Verifikation.**

**Verifikation**:
- `docker build -t mikiwa:test .` läuft durch (procps wird installiert)
- `bin/rails server -e production` startet lokal mit `RAILS_MASTER_KEY` ohne Fehler
- `docker compose -f deploy/docker-compose.yml config` zeigt keinen Syntax-Fehler

---

## Phase 2 — Image-Build via GitHub Actions

- [ ] **2.1** Workflow aus 1.3 lokal review (act / dry-run optional)
- [ ] **2.2** Branch mergen → Workflow läuft auf `main`
- [ ] **2.3** Verifizieren: Image erscheint unter
  `https://github.com/anka/mikiwa/pkgs/container/mikiwa` mit Tag `latest`
- [ ] **2.4** GHCR Personal Access Token (Classic) mit Scope `read:packages` erstellen.
  Token sicher ablegen (1Password o. Ä.) — wird in Phase 3 verwendet.

**Verifikation**: Image lokal pullen: `docker pull ghcr.io/anka/mikiwa:latest` (nach
`docker login ghcr.io`).

---

## Phase 3 — Server-Vorbereitung

Alles als `root` auf `mentalflares` (`ssh root@mentalflares`).

- [x] **3.1** Host-Pakete + Verzeichnisse angelegt (`sqlite3` 3.37.2 installiert, Verzeichnisse mit UID/GID 1000 für `storage`+`logs`, root für `backups`+`scripts`). Hinweis: UID 1000 entspricht auf dem Host dem User `ghost-mgr` — numerisch identisch zum `rails`-User im Container, daher unkritisch.
- [x] **3.2** GHCR-Login mit PAT (User `anka`) erfolgreich, Credentials in `/root/.docker/config.json`
- [x] **3.3** `.env` unter `/home/mikiwa/.env` angelegt (Mode 600, owner root) mit allen Variablen aus `deploy/.env.example`
- [x] **3.4** `docker-compose.yml` nach `/home/mikiwa/docker-compose.yml` (root:root, 644)
- [x] **3.5** Backup-Script unter `/home/mikiwa/scripts/backup.sh` (root:root, 750)
- [x] **3.6** Cron-Eintrag `/etc/cron.d/mikiwa-backup` installiert (root:root, 644)
- [x] **3.7** Logrotate-Config `/etc/logrotate.d/mikiwa` installiert (root:root, 644)

**Verifikation**:
- `ls -la /home/mikiwa/` → Owner/Permissions korrekt
- `docker pull ghcr.io/anka/mikiwa:latest` erfolgreich (Digest `sha256:0ec37697…`)
- `logrotate -d /etc/logrotate.d/mikiwa` → Pattern wird korrekt erkannt, switched zu uid/gid 1000 für Rotation
- `docker compose config --quiet` → kein Syntax-Fehler

---

## Phase 4 — Erststart der Container

- [ ] **4.1** Pull aktuelles Image: `cd /home/mikiwa && docker compose pull`
- [ ] **4.2** Migration laufen lassen (one-shot):
  `docker compose run --rm migrate`
  → muss mit Exit 0 enden; SQLite-Dateien erscheinen unter `/home/mikiwa/storage/`
- [ ] **4.3** Services starten: `docker compose up -d web worker`
- [ ] **4.4** Health prüfen:
  - `docker compose ps` zeigt beide `healthy`
  - `curl -fsS http://127.0.0.1:8080/up` → HTTP 200
  - `tail -f /home/mikiwa/logs/production.log` zeigt Bootlog

**Verifikation**: App ist lokal über loopback erreichbar; Worker läuft; keine Restart-Loops.

---

## Phase 5 — nginx vhost + SSL

- [ ] **5.1** DNS prüfen: `dig +short app.mikiwa.at` → A-Record zeigt auf
  Server-IP `mentalflares`. (Bei Bedarf vorher anlegen!)
- [ ] **5.2** vhost installieren:
  ```
  cp deploy/nginx/app.mikiwa.at.conf /etc/nginx/sites-available/app.mikiwa.at
  ln -s /etc/nginx/sites-available/app.mikiwa.at /etc/nginx/sites-enabled/app.mikiwa.at
  nginx -t && systemctl reload nginx
  ```
- [ ] **5.3** Initialer HTTP-Reach-Test:
  `curl -I http://app.mikiwa.at/up` → 200 (vor HTTPS-Aktivierung)
- [ ] **5.4** SSL via certbot (nginx-Plugin, bestehende Installation):
  ```
  certbot --nginx -d app.mikiwa.at --redirect --no-eff-email -m <admin@mail>
  ```
- [ ] **5.5** Verifizieren:
  - `curl -I https://app.mikiwa.at/up` → 200
  - `curl -I http://app.mikiwa.at/` → 301 → https
  - SSL-Test via `curl -fsS https://app.mikiwa.at/` zeigt Login-Seite
- [ ] **5.6** Auto-Renewal-Check: `certbot renew --dry-run`

**Verifikation**: App von außen via HTTPS erreichbar, kein Mixed-Content-Warning.

---

## Phase 6 — Betriebsabsicherung

- [ ] **6.1** Backup einmal manuell testen:
  `/home/mikiwa/scripts/backup.sh && ls -la /home/mikiwa/backups/`
- [ ] **6.2** Restore-Probe (in `/tmp`, nicht produktiv!):
  Backup-Datei entpacken, `sqlite3 .schema` prüfen → ohne Fehler lesbar
- [ ] **6.3** Logrotate-Test:
  `logrotate -f /etc/logrotate.d/mikiwa` (force) → `production.log.1.gz` entsteht;
  App läuft weiter (copytruncate hält File-Handle)
- [ ] **6.4** Reboot-Test:
  `reboot` → nach Hochfahren prüfen, dass Mikiwa-Container automatisch laufen
  (`docker ps`), DBs intakt
- [ ] **6.5** Smoke-Test im Browser:
  - Login mit Caretaker-Account
  - Eine Aktion auslösen, die einen Background-Job enqueued (z. B. Foto-Upload mit Vision-Klassifikation)
  - Logs zeigen Job-Execution durch Worker
- [ ] **6.6** Eintrag im Operations-Cheatsheet ergänzen, falls Abweichungen auftraten

**Verifikation**: System ist ohne manuelle Eingriffe wieder anlauffähig; Daten persistieren.

---

## Phase 7 — Dokumentation finalisieren

- [ ] **7.1** `docs/deployment.md` mit allen tatsächlichen Werten aktualisieren (Server-IP, Domain, Image-Tag, Port-Vergabe)
- [ ] **7.2** Plan-Datei mit allen Häkchen und Notizen committen
- [ ] **7.3** Im Team-Kanal verkünden + Server-Credentials in Passwort-Manager hinterlegen

---

## Out of Scope (separat tracken)

- `engageful` lauscht aktuell auf `0.0.0.0:9000` statt `127.0.0.1:9000`. Sicherheitsrelevant,
  aber nicht Teil dieses Tickets. → Eigenes Ticket anlegen.
- Migration des Servers von Ubuntu 22.04 → 24.04. → Eigenes Ticket.
- Monitoring/Alerting (Uptime, Disk, Memory). → Eigenes Ticket.
