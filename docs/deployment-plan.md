# Deployment-Plan: Mikiwa auf mentalflares

Strukturierter, abarbeitbarer Plan für das initiale Production-Deployment der Rails-App
auf dem bestehenden Server `mentalflares` (Ubuntu 22.04, DigitalOcean).

**Statusführung**: Jeden Schritt nach Abschluss mit `[x]` markieren. Bei Abweichungen vom
Plan einen kurzen Vermerk unter dem Schritt ergänzen.

**Quellinformationen**: Server-Bestandsaufnahme, Konventionen und Betriebs-Cheatsheet liegen
in [`docs/deployment.md`](./deployment.md). Bei jeder Änderung dort den Stand pflegen.

---

## Phase 1 — Repo-Anpassungen (lokal)

- [ ] **1.1** `config/environments/production.rb` patchen
  - `config.assume_ssl = true` aktivieren (nginx terminiert SSL)
  - `config.hosts << "app.mikiwa.at"` (DNS-Rebinding-Schutz)
  - Logger auf Datei umstellen: `Rails.root.join("log/production.log")`, TaggedLogging behalten
  - `silence_healthcheck_path` und `force_ssl` unverändert lassen
- [ ] **1.2** `bin/docker-entrypoint` anpassen — `db:prepare`-Block entfernen
  (Migration-Service übernimmt). Entrypoint nur noch `exec "${@}"`.
- [ ] **1.3** `.github/workflows/docker-publish.yml` erstellen
  - Trigger: Push auf `main`
  - Build via `docker/build-push-action`, Plattform `linux/amd64`
  - Push als `ghcr.io/anka/mikiwa:latest` **und** `ghcr.io/anka/mikiwa:sha-<short>`
  - Cache: GHA-Cache (`type=gha`)
- [ ] **1.4** Compose-Dateien lokal vorbereiten (werden später auf Server kopiert)
  - `deploy/docker-compose.yml` — Services: `migrate`, `web`, `worker`
  - `deploy/.env.example` — alle erforderlichen Variablen mit Kommentaren
  - `deploy/nginx/app.mikiwa.at.conf` — vhost-Vorlage
  - `deploy/logrotate/mikiwa` — Logrotate-Snippet
  - `deploy/scripts/backup.sh` — SQLite-Backup mit Retention 14 Tage
  - `deploy/cron/mikiwa-backup` — Cron-Eintrag
- [ ] **1.5** `docs/deployment.md` mit allen Setup-Schritten + Server-Inventar pflegen
- [ ] **1.6** `AGENTS.md` ergänzen: Verweis auf `docs/deployment.md` in passendem Abschnitt
- [ ] **1.7** Branch `feature/server-deployment` (oder vergleichbar) anlegen, Änderungen
  committen, PR gegen `main` öffnen. **Merge erst nach Phase 2.**

**Verifikation**: `bin/rails server -e production` lokal startet ohne Fehler;
`docker build -t mikiwa:test .` läuft durch.

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

- [ ] **3.1** Verzeichnisse anlegen und Owner setzen (UID/GID 1000 = Rails-User im Container)
  ```
  mkdir -p /home/mikiwa/{storage,logs,backups,scripts}
  chown -R 1000:1000 /home/mikiwa/storage /home/mikiwa/logs
  chown root:root /home/mikiwa/backups /home/mikiwa/scripts
  chmod 750 /home/mikiwa/backups /home/mikiwa/scripts
  ```
- [ ] **3.2** GHCR-Login (Token aus 2.4)
  ```
  echo "<GHCR_PAT>" | docker login ghcr.io -u <github-username> --password-stdin
  ```
  → schreibt nach `/root/.docker/config.json`
- [ ] **3.3** `.env` unter `/home/mikiwa/.env` anlegen (Mode 600, owner root)
  - `RAILS_MASTER_KEY=` (Inhalt von lokal `config/master.key`)
  - `OPENAI_API_KEY=` (Dev-Key)
  - `MIKIWA_WEB_PORT=8080`
  - `WEB_CONCURRENCY=2`
  - `RAILS_MAX_THREADS=3`
  - `JOB_CONCURRENCY=1`
  - `MIKIWA_IMAGE_TAG=latest`
- [ ] **3.4** `docker-compose.yml` nach `/home/mikiwa/docker-compose.yml` kopieren
  (aus `deploy/docker-compose.yml` im Repo)
- [ ] **3.5** Backup-Script nach `/home/mikiwa/scripts/backup.sh` kopieren, `chmod 750`
- [ ] **3.6** Cron-Eintrag `/etc/cron.d/mikiwa-backup` installieren
- [ ] **3.7** Logrotate-Config `/etc/logrotate.d/mikiwa` installieren

**Verifikation**:
- `ls -la /home/mikiwa/` zeigt korrekte Owner/Permissions
- `docker pull ghcr.io/anka/mikiwa:latest` erfolgreich
- `logrotate -d /etc/logrotate.d/mikiwa` zeigt erwartete Rotation

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
