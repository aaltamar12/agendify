# Deploy a Producción — OVH VPS

> **Última actualización:** 2026-03-26
>
> **Arquitectura:** Frontend en Vercel (agendity.co) + Backend en OVH VPS (api.agendity.co)

---

## Arquitectura de producción

```mermaid
graph TB
    subgraph Vercel["Vercel (CDN + Edge)"]
        WEB["Next.js PWA<br/>agendity.co"]
    end

    subgraph OVH["OVH VPS (Ubuntu 24.04)"]
        NGINX["Nginx<br/>:80/:443 SSL"]
        API["Rails API (Puma)<br/>:3001"]
        SIDEKIQ["Sidekiq<br/>(background jobs)"]
        PG["PostgreSQL 16<br/>:5432"]
        REDIS["Redis 7<br/>:6379"]
        NATS["NATS Server<br/>:4222 + :8222 WS"]
    end

    WEB -->|HTTPS| NGINX
    NGINX -->|/api/| API
    NGINX -->|/admin| API
    NGINX -->|/nats| NATS
    NGINX -->|/rails/active_storage/| API
    API --> PG
    API --> REDIS
    API --> NATS
    SIDEKIQ --> PG
    SIDEKIQ --> REDIS
    SIDEKIQ --> NATS
```

**Decisión:** Frontend en Vercel (CDN global, SSL automático, zero config) + Backend en VPS (control total, costo fijo). El frontend llama a `https://api.agendity.co/api/v1/`.

---

## 1. Setup inicial del VPS

### 1.1 Acceso SSH

```bash
# Reemplazar IP_DEL_VPS con la IP real de OVH
ssh root@IP_DEL_VPS

# Crear usuario no-root
adduser agendity
usermod -aG sudo agendity
rsync --archive --chown=agendity:agendity ~/.ssh /home/agendity

# Desde ahora usar este usuario
su - agendity
```

### 1.2 Actualizar sistema

```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y curl git ufw fail2ban htop
```

### 1.3 Firewall (UFW)

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw enable
sudo ufw status
```

### 1.4 SSH hardening

```bash
sudo nano /etc/ssh/sshd_config
# Cambiar:
#   PermitRootLogin no
#   PasswordAuthentication no
sudo systemctl restart sshd
```

---

## 2. Instalar Docker + Docker Compose

```bash
# Docker oficial
curl -fsSL https://get.docker.com | sh

# Agregar usuario al grupo docker
sudo usermod -aG docker agendity
newgrp docker

# Verificar
docker --version
docker compose version
```

---

## 3. Clonar repositorio

```bash
cd /home/agendity
git clone git@github.com:aaltamar12/agendify.git agendity
cd agendity
```

---

## 4. Configurar variables de entorno

### 4.1 Generar secretos

```bash
# En tu máquina local con Rails instalado, o en el VPS después de build:
docker run --rm -it ruby:3.4.7-slim ruby -rsecurerandom -e 'puts SecureRandom.hex(64)'
# Repetir para cada secreto
```

### 4.2 Crear archivo .env

```bash
cp docker/.env.example .env
nano .env
```

Contenido del `.env`:

```bash
# ============================================================
# DATABASE
# ============================================================
POSTGRES_PASSWORD=<generar_password_seguro>

# ============================================================
# RAILS
# ============================================================
SECRET_KEY_BASE=<rails_secret_64_chars>
DEVISE_JWT_SECRET_KEY=<jwt_secret_64_chars>

# Active Record Encryption (para datos de pago encriptados)
ACTIVE_RECORD_ENCRYPTION_PRIMARY_KEY=<32_chars_random>
ACTIVE_RECORD_ENCRYPTION_DETERMINISTIC_KEY=<32_chars_random>
ACTIVE_RECORD_ENCRYPTION_KEY_DERIVATION_SALT=<32_chars_random>

# ============================================================
# URLs
# ============================================================
AGENDITY_WEB_URL=https://agendity.co
API_HOST=https://api.agendity.co
NEXT_PUBLIC_API_URL=https://api.agendity.co
NEXT_PUBLIC_APP_URL=https://agendity.co
NEXT_PUBLIC_NATS_WS_URL=wss://api.agendity.co/nats
NATS_AUTH_TOKEN=<generar_token_nats>

# ============================================================
# EXTERNAL SERVICES
# ============================================================
PEXELS_API_KEY=<tu_api_key_pexels>

# ============================================================
# EMAIL (SMTP)
# ============================================================
SMTP_ADDRESS=smtp.resend.com
SMTP_PORT=587
SMTP_USERNAME=resend
SMTP_PASSWORD=<tu_api_key_resend>
SMTP_DOMAIN=agendity.co
MAILER_FROM=Agendity <noreply@agendity.co>
```

---

## 5. SSL con Let's Encrypt

### 5.1 Instalar Certbot

```bash
sudo apt install -y certbot
```

### 5.2 Obtener certificado (antes de levantar Nginx)

```bash
# Detener nginx si está corriendo
docker compose down nginx 2>/dev/null

# Obtener certificado standalone
sudo certbot certonly --standalone -d api.agendity.co --email soporte@agendity.co --agree-tos --no-eff-email

# Los certificados quedan en:
# /etc/letsencrypt/live/api.agendity.co/fullchain.pem
# /etc/letsencrypt/live/api.agendity.co/privkey.pem
```

### 5.3 Auto-renovación

```bash
# Certbot ya instala un timer de systemd, verificar:
sudo systemctl status certbot.timer

# Test de renovación:
sudo certbot renew --dry-run
```

---

## 6. Nginx con SSL

Actualizar `docker/nginx.conf` para producción:

```nginx
# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name api.agendity.co;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl http2;
    server_name api.agendity.co;

    # SSL
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    # CORS for frontend (agendity.co)
    add_header Access-Control-Allow-Origin "https://agendity.co" always;
    add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
    add_header Access-Control-Allow-Headers "Authorization, Content-Type, X-Requested-With" always;
    add_header Access-Control-Allow-Credentials "true" always;

    # Max upload size (comprobantes de pago)
    client_max_body_size 10M;

    # API
    location /api/ {
        proxy_pass http://api:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ActiveAdmin
    location /admin {
        proxy_pass http://api:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # ActiveStorage files
    location /rails/active_storage/ {
        proxy_pass http://api:3001;
        proxy_set_header Host $host;
    }

    # Sidekiq Web (admin only — proteger con IP o basic auth)
    location /admin/sidekiq {
        proxy_pass http://api:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # NATS WebSocket
    location /nats {
        proxy_pass http://nats:8222;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_read_timeout 86400;
    }

    # Health check
    location /health {
        proxy_pass http://api:3001/api/v1/health;
    }
}
```

### Montar certificados en Docker

Actualizar `docker-compose.yml` (sección nginx):

```yaml
nginx:
  image: nginx:alpine
  depends_on:
    - api
    - nats
  volumes:
    - ./docker/nginx.conf:/etc/nginx/conf.d/default.conf:ro
    - /etc/letsencrypt/live/api.agendity.co/fullchain.pem:/etc/nginx/ssl/fullchain.pem:ro
    - /etc/letsencrypt/live/api.agendity.co/privkey.pem:/etc/nginx/ssl/privkey.pem:ro
  ports:
    - "80:80"
    - "443:443"
  restart: unless-stopped
```

---

## 7. DNS (GoDaddy)

Agregar registro A para el subdominio de la API:

| Tipo | Nombre | Valor | TTL |
|------|--------|-------|-----|
| A | api | IP_DEL_VPS | 600 |

El frontend (agendity.co) sigue en Vercel con los registros existentes.

---

## 8. Primer deploy

```bash
cd /home/agendity/agendity

# Build de todas las imágenes
docker compose build

# Levantar servicios de infraestructura primero
docker compose up -d postgres redis nats
sleep 5

# Crear base de datos y migrar
docker compose run --rm api bundle exec rails db:create db:migrate

# Seed de datos iniciales
docker compose run --rm api bundle exec rails db:seed

# Levantar todo
docker compose up -d

# Verificar que todo está arriba
docker compose ps
docker compose logs --tail=20 api
```

### Verificar

```bash
# Health check
curl -s https://api.agendity.co/api/v1/public/plans | jq .

# ActiveAdmin
# Abrir: https://api.agendity.co/admin
```

---

## 9. Script de deploy mejorado

Reemplazar `scripts/deploy.sh`:

```bash
#!/bin/bash
set -e

DEPLOY_DIR="/home/agendity/agendity"
BACKUP_DIR="/home/agendity/backups"
DATE=$(date +%Y%m%d_%H%M%S)

echo "=========================================="
echo "  Deploying Agendity — $DATE"
echo "=========================================="

cd $DEPLOY_DIR

# 1. Backup DB antes de deploy
echo "📦 Backing up database..."
mkdir -p $BACKUP_DIR
docker compose exec -T postgres pg_dump -U agendity agendity_production | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"
echo "  ✅ Backup: $BACKUP_DIR/db_$DATE.sql.gz"

# 2. Pull latest code
echo "📥 Pulling latest code..."
git pull origin main

# 3. Build images
echo "🏗️  Building images..."
docker compose build

# 4. Run migrations
echo "🔄 Running migrations..."
docker compose run --rm api bundle exec rails db:migrate

# 5. Restart services (rolling)
echo "🚀 Restarting services..."
docker compose up -d --remove-orphans

# 6. Verify health
echo "🔍 Verifying..."
sleep 5
if curl -sf https://api.agendity.co/api/v1/public/plans > /dev/null; then
    echo "  ✅ API responding correctly"
else
    echo "  ❌ API not responding — check logs!"
    docker compose logs --tail=50 api
    exit 1
fi

# 7. Cleanup old backups (keep last 30)
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete

echo ""
echo "=========================================="
echo "  ✅ Deploy complete!"
echo "  API: https://api.agendity.co"
echo "  Admin: https://api.agendity.co/admin"
echo "=========================================="
```

```bash
chmod +x scripts/deploy.sh
```

---

## 10. Backups automatizados

### Cron para backup diario

```bash
crontab -e
```

Agregar:

```
# Backup diario a las 3am
0 3 * * * /home/agendity/agendity/scripts/backup.sh >> /home/agendity/logs/backup.log 2>&1
```

### Script de backup (`scripts/backup.sh`)

```bash
#!/bin/bash
set -e

BACKUP_DIR="/home/agendity/backups"
DATE=$(date +%Y%m%d)
cd /home/agendity/agendity

mkdir -p $BACKUP_DIR

# DB dump
docker compose exec -T postgres pg_dump -U agendity agendity_production | gzip > "$BACKUP_DIR/db_$DATE.sql.gz"

# ActiveStorage files (logos, comprobantes)
docker compose exec -T api tar czf - /rails/storage 2>/dev/null > "$BACKUP_DIR/storage_$DATE.tar.gz" || true

# Cleanup (mantener últimos 30 días)
find $BACKUP_DIR -name "db_*.sql.gz" -mtime +30 -delete
find $BACKUP_DIR -name "storage_*.tar.gz" -mtime +30 -delete

echo "[$(date)] Backup completado: db_$DATE.sql.gz"
```

```bash
chmod +x scripts/backup.sh
mkdir -p /home/agendity/logs
```

---

## 11. Monitoreo

### Logs en tiempo real

```bash
# Todos los servicios
docker compose logs -f

# Solo API
docker compose logs -f api

# Solo Sidekiq (jobs)
docker compose logs -f sidekiq

# Solo errores
docker compose logs -f api 2>&1 | grep -i error
```

### Healthchecks en docker-compose.yml

Agregar healthchecks a los servicios existentes:

```yaml
postgres:
  healthcheck:
    test: ["CMD-SHELL", "pg_isready -U agendity"]
    interval: 10s
    timeout: 5s
    retries: 5

redis:
  healthcheck:
    test: ["CMD", "redis-cli", "ping"]
    interval: 10s
    timeout: 5s
    retries: 5

api:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:3001/api/v1/public/plans"]
    interval: 30s
    timeout: 10s
    retries: 3
```

### Estado rápido

```bash
# Ver estado de todos los contenedores
docker compose ps

# Uso de recursos
docker stats --no-stream

# Espacio en disco
df -h
docker system df
```

---

## 12. Vercel (Frontend)

El frontend se deploya automáticamente en Vercel. Solo necesita estas variables de entorno en Vercel:

| Variable | Valor producción |
|----------|------------------|
| `NEXT_PUBLIC_API_URL` | `https://api.agendity.co` |
| `NEXT_PUBLIC_APP_URL` | `https://agendity.co` |
| `NEXT_PUBLIC_NATS_WS_URL` | `wss://api.agendity.co/nats` |
| `NEXT_PUBLIC_NATS_AUTH_TOKEN` | `<token_nats_produccion>` |

**No necesita Docker ni VPS.** Vercel se encarga del build, CDN y SSL.

---

## 13. GitHub Actions CI/CD (opcional)

Crear `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Production

on:
  push:
    branches: [main]
    paths:
      - 'agendity-api/**'
      - 'docker-compose.yml'
      - 'docker/**'

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16-alpine
        env:
          POSTGRES_USER: agendity
          POSTGRES_PASSWORD: test
          POSTGRES_DB: agendity_test
        ports: ['5432:5432']
      redis:
        image: redis:7-alpine
        ports: ['6379:6379']
    defaults:
      run:
        working-directory: agendity-api
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.4.7'
          bundler-cache: true
          working-directory: agendity-api
      - run: bundle exec rails db:create db:migrate
        env:
          DATABASE_URL: postgres://agendity:test@localhost:5432/agendity_test
          RAILS_ENV: test
      - run: bundle exec rspec
        env:
          DATABASE_URL: postgres://agendity:test@localhost:5432/agendity_test
          RAILS_ENV: test

  deploy:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - name: Deploy via SSH
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: agendity
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /home/agendity/agendity
            bash scripts/deploy.sh
```

Secrets requeridos en GitHub:
- `VPS_HOST`: IP del VPS
- `VPS_SSH_KEY`: Clave privada SSH

---

## 14. Restaurar backup

```bash
# Restaurar DB desde backup
gunzip < /home/agendity/backups/db_20260326.sql.gz | docker compose exec -T postgres psql -U agendity agendity_production

# Restaurar storage
docker cp /home/agendity/backups/storage_20260326.tar.gz agendity-api-1:/tmp/
docker compose exec api tar xzf /tmp/storage_20260326.tar.gz -C /
```

---

## Checklist pre-producción

- [ ] VPS contratado en OVH (mínimo 2 vCPU, 4GB RAM, 80GB SSD)
- [ ] DNS: registro A `api` → IP del VPS en GoDaddy
- [ ] SSH configurado (clave pública, root login deshabilitado)
- [ ] Firewall UFW activo (22, 80, 443)
- [ ] Docker + Docker Compose instalados
- [ ] `.env` configurado con todos los secretos generados
- [ ] Certificado SSL obtenido con Certbot
- [ ] `docker compose up -d` — todos los servicios verdes
- [ ] `db:migrate` + `db:seed` ejecutados
- [ ] Admin accesible en `/admin`
- [ ] API responde en `/api/v1/public/plans`
- [ ] NATS WebSocket conecta desde el frontend
- [ ] Backup cron configurado
- [ ] Variables de Vercel apuntando a `api.agendity.co`
- [ ] Probar flujo completo: registro → onboarding → reserva → pago → check-in

---

## Archivos clave

| Archivo | Descripción |
|---------|-------------|
| `docker-compose.yml` | Orquestación de 7 servicios |
| `agendity-api/Dockerfile` | Image Rails multi-stage |
| `agendity-web/Dockerfile` | Image Next.js multi-stage (solo si unificamos en VPS) |
| `docker/nginx.conf` | Reverse proxy + SSL + WebSocket |
| `docker/nats.conf` | Config NATS con WebSocket + auth |
| `docker/.env.example` | Template de variables de entorno |
| `scripts/deploy.sh` | Script de deploy con backup |
| `scripts/backup.sh` | Backup automático (DB + storage) |
| `.github/workflows/deploy.yml` | CI/CD con GitHub Actions |

---

## Costos estimados (OVH)

| Recurso | Especificación | Costo mensual |
|---------|---------------|---------------|
| VPS OVH | 2 vCPU, 4GB RAM, 80GB SSD | ~$12 USD |
| Dominio (.co) | agendity.co (GoDaddy) | ~$30 USD/año |
| Email (Resend) | 3,000 emails/mes gratis | $0 |
| SSL | Let's Encrypt | $0 |
| **Total** | | **~$12 USD/mes** |
