# Deployment & Operations — Mikiwa

Diese Datei ist die **Single Source of Truth** für alles rund um das Production-Deployment
auf `mentalflares`. Sie enthält das Server-Inventar (damit die SSH-Analyse nicht jedes Mal
neu gemacht werden muss), das Soll-Setup der Mikiwa-App, sowie ein Operations-Cheatsheet
für den Tagesbetrieb.

> Bei jeder Änderung am Server, an der App-Konfiguration oder am Build-Prozess: **diese
> Datei pflegen**. Stand des Plans für das initiale Setup: [`docs/deployment-plan.md`](./deployment-plan.md).

---

## 1. Server-Inventar (Stand: 2026-05-17)

### 1.1 Host & Zugang

| Feld | Wert |
|---|---|
| Hostname | `mentalflares` (Display-Name: `jademind-ghost`) |
| Provider | DigitalOcean Droplet |
| OS | Ubuntu 22.04.5 LTS (Jammy), Kernel 5.15 |
| Hardware | 2 vCPU, 3.8 GiB RAM, 49 GiB Disk (≈33 GiB frei), 2 GiB Swap |
| SSH | `ssh root@mentalflares` (authorized_keys, kein Passwort) |

### 1.2 Globale Tooling-Versionen

| Tool | Version | Pfad / Notiz |
|---|---|---|
| Docker Engine | 29.5.0 | systemd-managed |
| Docker Compose | v5.1.3 | als `docker compose` Subcommand |
| nginx | 1.18.0 (Ubuntu) | `systemctl status nginx`, Layout `sites-available/sites-enabled` |
| certbot | 5.6.0 | `/usr/bin/certbot` (snap), Plugin `nginx`, auto-renew via `certbot.timer` + `snap.certbot.renew.timer` |
| UFW | aktiv | erlaubt: 22/tcp (limit), 80,443/tcp (allow), 60000–61000/udp (mosh) |
| MySQL | system-paket | lauscht nur lokal: 127.0.0.1:3306 + 127.0.0.1:33060 |
| Postfix | system-paket | lauscht nur lokal: 127.0.0.1:25 |
| Ghost CMS | systemd-service | 127.0.0.1:2369 (für `www.mentalflares.com`) |

Keine `/etc/docker/daemon.json` vorhanden (Defaults aktiv).

### 1.3 Bestehende Web-Apps (vor Mikiwa-Deployment)

| App | Domain | Container | Loopback-Port | Compose-Dir |
|---|---|---|---|---|
| storyteller | `app.hoernest.com` | `storyteller-app-1` | 127.0.0.1:8000 | `/home/storyteller/` |
| engageful | `engageful.jademind.com` | `engageful-backend` | **0.0.0.0:9000** ⚠ | `/home/engageful/` |
| Ghost CMS | `www.mentalflares.com` | systemd-Service | 127.0.0.1:2369 | `/home/ghost-mgr/` |

⚠ `engageful` bindet global auf 0.0.0.0 — Out-of-Scope für Mikiwa-Deployment, aber sicherheitsrelevant.

### 1.4 nginx-Konfiguration

- Pfad: `/etc/nginx/nginx.conf` (Default-User `www-data`, `worker_processes auto`)
- vhosts unter `/etc/nginx/sites-available/`, aktiviert via Symlink in `sites-enabled/`
- Bestehende vhosts:
  - `engageful.jademind.com`
  - `storyteller.conf` (HTTPS) + `storyteller_http.conf` (für `app.hoernest.com`)
  - `www.mentalflares.com.conf` + `www.mentalflares.com-ssl.conf`
- Logs landen in `/var/log/nginx/*.log`, Rotation via `/etc/logrotate.d/nginx` (daily, rotate 14, compress)
- SSL-Defaults (Includes durch certbot): `/etc/letsencrypt/options-ssl-nginx.conf`, `/etc/letsencrypt/ssl-dhparams.pem`

### 1.5 certbot-Zertifikate

| Cert | Domain(s) | Pfad | Renewal |
|---|---|---|---|
| `app.hoernest.com` | app.hoernest.com | `/etc/letsencrypt/live/app.hoernest.com/` | automatisch |
| `engageful.jademind.com` | engageful.jademind.com | `/etc/letsencrypt/live/engageful.jademind.com/` | automatisch |
| `app.mikiwa.at` | _(noch zu beantragen)_ | _(siehe Plan Phase 5)_ | — |

### 1.6 Port-Belegung (loopback + extern)

| Port | Bind | Dienst |
|---|---|---|
| 22/tcp | 0.0.0.0 | SSH |
| 25/tcp | 127.0.0.1 | Postfix |
| 53/tcp | 127.0.0.53 | systemd-resolved |
| 80/tcp | 0.0.0.0 | nginx |
| 443/tcp | 0.0.0.0 | nginx |
| 2369/tcp | 127.0.0.1 | Ghost CMS |
| 3306/tcp | 127.0.0.1 | MySQL |
| 8000/tcp | 127.0.0.1 | storyteller |
| **8080/tcp** | 127.0.0.1 | **reserviert für Mikiwa-Web** |
| 9000/tcp | 0.0.0.0 ⚠ | engageful |
| 33060/tcp | 127.0.0.1 | MySQL X-Protocol |

**Regel für neue Apps**: ausschließlich `127.0.0.1:<port>` mappen, nie `0.0.0.0`.
Nächste freie Konventions-Ports: 8081, 8082, …

### 1.7 /home-Layout

```
/home/
├── engageful/       (root:root)    docker-compose.yml + .env + ./data
├── ghost-mgr/       (ghost-mgr)    Ghost-Installation
├── mikiwa/          (siehe §2)
└── storyteller/     (root:root)    docker-compose.yml + .env + ./db ./logs ./output
```

---

## 2. Mikiwa — Soll-Setup

### 2.1 Verzeichnislayout auf dem Server

```
/home/mikiwa/
├── docker-compose.yml      (root:root, 644)
├── .env                    (root:root, 600)   – Secrets
├── storage/                (1000:1000, 755)   – SQLite-DBs + Active Storage
│   ├── production.sqlite3
│   ├── production_cache.sqlite3
│   ├── production_queue.sqlite3
│   ├── production_cable.sqlite3
│   └── …Active-Storage-Blobs…
├── logs/                   (1000:1000, 755)   – Rails-Logs + Container-Stdout/Stderr
│   └── production.log
├── backups/                (root:root, 750)   – tägliche SQLite-Snapshots, gz, 14 Tage
└── scripts/                (root:root, 750)
    └── backup.sh
```

> **UID/GID 1000** entspricht dem `rails`-User im Container (siehe `Dockerfile`).
> Backups und Scripts laufen als root, dürfen aber nicht für den Container schreibbar sein.

### 2.2 Image & Registry

| Feld | Wert |
|---|---|
| Registry | `ghcr.io` |
| Image | `ghcr.io/anka/mikiwa` |
| Standard-Tag | `latest` (zusätzlich `sha-<short>` pro Commit für Rollback) |
| Build | GitHub Actions auf Push nach `main` |
| Pull-Auth | GHCR PAT (Scope `read:packages`) via `docker login ghcr.io` auf dem Server |

### 2.3 docker-compose.yml — Services

| Service | Aufgabe | Port-Mapping | Healthcheck | Memory-Limit |
|---|---|---|---|---|
| `migrate` | `bin/rails db:prepare`, one-shot | — | — | 256M |
| `web` | Puma + Thruster | `127.0.0.1:8080:80` | `curl -fsS http://localhost/up` | 1G |
| `worker` | Solid Queue Worker (`bin/jobs`) | — | `pgrep -f solid_queue` (benötigt `procps` im Image) | 512M |

Gemeinsam:
- `image: ghcr.io/anka/mikiwa:${MIKIWA_IMAGE_TAG:-latest}`, `pull_policy: always`
- `restart: unless-stopped` (web/worker; `migrate`: `no`)
- `env_file: .env`
- Volumes:
  - `/home/mikiwa/storage:/rails/storage`
  - `/home/mikiwa/logs:/rails/log`
- `web` und `worker` haben `depends_on: migrate (condition: service_completed_successfully)`
- ENV `SOLID_QUEUE_IN_PUMA=false` (Worker läuft separat)
- Eigenes Bridge-Network `mikiwa`

### 2.4 Erforderliche ENV-Variablen (`.env`)

| Variable | Pflicht | Quelle | Notiz |
|---|---|---|---|
| `RAILS_MASTER_KEY` | ✔ | lokal `config/master.key` | entschlüsselt `credentials.yml.enc` (Mailjet-Keys etc.) |
| `OPENAI_API_KEY` | ✔ | Dev-Key (vorerst) | für Vision-Klassifikation von Einkaufslisten-Fotos |
| `MIKIWA_WEB_PORT` | ✔ | `8080` | Host-Port für Loopback-Binding |
| `MIKIWA_IMAGE_TAG` | optional | `latest` | für Rollback auf `sha-…` |
| `WEB_CONCURRENCY` | optional | `2` | Puma-Worker (Memory-bewusst auf 4 GiB Box) |
| `RAILS_MAX_THREADS` | **muss ≥ 5 sein** | `5` | Puma-Threads pro Worker **und** SQLite-Connection-Pool. Solid Queue braucht ≥ 5 Connections (3 worker threads + 1 dispatcher + 1 supervisor), sonst crasht der Worker-Container beim Boot. |
| `JOB_CONCURRENCY` | optional | `1` | Solid-Queue-Worker-Prozesse |

Mailjet-Credentials liegen **nicht** in `.env`, sondern in `credentials.yml.enc`
(entschlüsselt mit `RAILS_MASTER_KEY`).

### 2.5 nginx vhost (`/etc/nginx/sites-available/app.mikiwa.at`)

- Server-Name: `app.mikiwa.at`
- HTTP-Block (Port 80): Redirect auf HTTPS (nach certbot)
- HTTPS-Block (Port 443):
  - `proxy_pass http://127.0.0.1:8080`
  - Forward-Header: `Host`, `X-Real-IP`, `X-Forwarded-For`, `X-Forwarded-Proto https`, `X-Forwarded-Host`, `X-Forwarded-Port 443`
  - `client_max_body_size 25M` (für Bild-Uploads / Magic-Slideshow)
  - Timeouts `proxy_connect_timeout 60s`, `proxy_send_timeout 60s`, `proxy_read_timeout 60s`
  - Optional: `location /cable` mit WebSocket-Upgrade (nur falls Action Cable produktiv genutzt wird)
- SSL-Block wird durch `certbot --nginx` ergänzt.

### 2.6 Rails-Produktionsanpassungen

Diese sind in `config/environments/production.rb` permanent verankert:

- `config.assume_ssl = true` — nginx terminiert SSL, sonst Redirect-Loop wegen `force_ssl`
- `config.hosts << "app.mikiwa.at"` — DNS-Rebinding-Schutz
- Logger: Datei `log/production.log` (TaggedLogging), zusätzlich werden Container-stdout/stderr
  vom Compose-Service via shell-Redirect in dieselbe Datei geschrieben
  (`command: sh -c "exec ./bin/thrust ./bin/rails server >> /rails/log/production.log 2>&1"`)
- `silence_healthcheck_path = "/up"` (bereits aktiv)

### 2.7 Logging & Rotation

- **Quelle**: Rails-Logger schreibt direkt nach `/rails/log/production.log` (= `/home/mikiwa/logs/production.log`)
- **Container-stdout/stderr**: per shell-Redirect ebenfalls in dieselbe Datei
- **Rotation**: `/etc/logrotate.d/mikiwa`
  ```
  /home/mikiwa/logs/*.log {
      daily
      rotate 14
      compress
      delaycompress
      missingok
      notifempty
      copytruncate
      su 1000 1000
  }
  ```
  `copytruncate` ist Pflicht — Rails hält das File-Handle und würde nach `rotate` weiter ins alte Inode schreiben.

### 2.8 Backups

- Script: `/home/mikiwa/scripts/backup.sh` (chmod 750, owner root) — Quelle: `deploy/scripts/backup.sh`
- Voraussetzung auf dem Host: `sqlite3`-Paket installiert (`apt-get install -y sqlite3`)
- Methode: `sqlite3 <db> ".backup '<target>'"` (online-safe, korrektes Locking)
- Quellen: alle vier Production-DBs aus `/home/mikiwa/storage/`
- Ziel: `/home/mikiwa/backups/<db-name>-YYYY-MM-DD.sqlite3.gz`
- Retention: 14 Tage (`find -mtime +14 -delete`)
- Cron: `/etc/cron.d/mikiwa-backup` → `0 3 * * * root /home/mikiwa/scripts/backup.sh >> /home/mikiwa/logs/backup.log 2>&1`

> **Hinweis**: Active-Storage-Blobs unter `/home/mikiwa/storage/` werden vom Script
> **nicht** gesichert. Wenn das gewünscht ist, separat ergänzen (rsync + Retention).

---

## 3. Operations-Cheatsheet

Alle Befehle als `root` auf `mentalflares`. Working-Dir: `/home/mikiwa/`.

### 3.1 Deploy einer neuen Version

```bash
cd /home/mikiwa
docker compose pull                       # neuestes :latest holen
docker compose run --rm migrate           # Migrationen ausführen
docker compose up -d web worker           # Container ersetzen
docker compose ps                         # Health verifizieren
```

### 3.2 Rollback auf eine bestimmte SHA

```bash
cd /home/mikiwa
sed -i 's/^MIKIWA_IMAGE_TAG=.*/MIKIWA_IMAGE_TAG=sha-abcdef0/' .env
docker compose pull
docker compose up -d web worker
# nach erfolgreichem Test:
sed -i 's/^MIKIWA_IMAGE_TAG=.*/MIKIWA_IMAGE_TAG=latest/' .env
```

### 3.3 Logs ansehen

```bash
tail -f /home/mikiwa/logs/production.log              # Rails-Log
docker compose logs -f web                            # Container-Log (Docker JSON)
docker compose logs -f worker
journalctl -u nginx -f                                # nginx-Logs
tail -f /var/log/nginx/access.log /var/log/nginx/error.log
```

### 3.4 Rails-Console / DB-Console

```bash
cd /home/mikiwa
docker compose exec web bin/rails console
docker compose exec web bin/rails dbconsole
```

### 3.5 Manuelles Backup / Restore

```bash
# Backup
/home/mikiwa/scripts/backup.sh

# Restore (Beispiel — App vorher stoppen!)
cd /home/mikiwa
docker compose stop web worker
gunzip -c backups/production-2026-05-17.sqlite3.gz > storage/production.sqlite3
chown 1000:1000 storage/production.sqlite3
docker compose start web worker
```

### 3.6 Container neu starten

```bash
cd /home/mikiwa
docker compose restart web                            # nur web
docker compose down && docker compose up -d           # full restart (Migration läuft nicht)
docker compose run --rm migrate && docker compose up -d web worker   # mit Migration
```

### 3.7 Disk-/Volume-Check

```bash
df -h /home/mikiwa
du -sh /home/mikiwa/{storage,logs,backups}
ls -la /home/mikiwa/storage/*.sqlite3
docker system df
```

### 3.8 Zertifikat-Erneuerung manuell prüfen

```bash
certbot certificates                                  # Übersicht
certbot renew --dry-run                               # Renewal-Test
```

### 3.9 nginx-Reload nach Änderung

```bash
nginx -t && systemctl reload nginx
```

### 3.10 Notfall: alles stoppen

```bash
cd /home/mikiwa
docker compose down                                   # nur Mikiwa
systemctl stop nginx                                  # gesamter Webserver
```

---

## 4. Troubleshooting

| Symptom | Erste Schritte |
|---|---|
| `/up` antwortet nicht | `docker compose ps`, `docker compose logs web`, `tail /home/mikiwa/logs/production.log` |
| HTTPS-Redirect-Loop | `assume_ssl` in `production.rb` verifizieren; nginx-Header `X-Forwarded-Proto https` prüfen |
| 502 von nginx | Web-Container down oder Port 8080 nicht erreichbar — `ss -tlnp | grep 8080` |
| Worker-Jobs hängen | `docker compose logs worker`, `docker compose exec web bin/rails runner "puts SolidQueue::Job.failed.count"` |
| Disk voll | alte Backups prüfen (`ls /home/mikiwa/backups/`), `docker image prune`, `journalctl --vacuum-time=7d` |
| Container restarted laufend | `docker compose logs --tail=200 web` — meist Migration oder fehlende ENV-Variable |
| Logrotate erzeugt leere Datei | `copytruncate` in `/etc/logrotate.d/mikiwa` prüfen |

---

## 5. Änderungs-Konventionen

- **Server-Änderungen** dokumentieren: jede Anpassung an `/etc/nginx/`, `/etc/logrotate.d/`,
  `/home/mikiwa/`, ENV-Variablen, Cron — hier in `docs/deployment.md` festhalten (Abschnitte
  §1, §2 entsprechend updaten) **und** commit.
- **Repo-Änderungen** an Deployment-Artefakten: Dateien unter `deploy/` im Repo sind die
  authoritative Quelle. Was auf dem Server liegt, muss daraus generiert sein.
- **Reproduzierbarkeit**: Server muss jederzeit aus diesem Dokument + dem Repo komplett
  neu aufgebaut werden können.
