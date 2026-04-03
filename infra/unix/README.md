# Unix Deployment

Bu dizin, Eventra'yi Docker/Podman kullanmadan klasik Unix sunucuda ayri servisler olarak calistirmak icin gereken iskeleti icerir.

Hedef yapi:

- `api` -> `systemd` servisi
- `rule-engine` -> `systemd` servisi
- `cache-loader` -> `systemd` servisi
- `frontend` -> `vite build` sonucu static dosya, `caddy` ile servis edilir
- `postgres`, `redis`, `kafka` -> host servisleri

## Onerilen dizin yapisi

```text
/opt/eventra/current
/etc/eventra/eventra.env
/etc/systemd/system/eventra-api.service
/etc/systemd/system/eventra-rule-engine.service
/etc/systemd/system/eventra-cache-loader.service
/etc/caddy/Caddyfile
```

## 1. Sunucu paketleri

Ubuntu/Debian:

```bash
apt-get update
apt-get install -y curl git build-essential caddy redis-server postgresql
```

Node 20:

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs
```

Kafka'yi host servisi olarak ayri kurman gerekir.

## 2. Kodu yerlestir

```bash
mkdir -p /opt/eventra
git clone <repo-url> /opt/eventra/current
cd /opt/eventra/current
npm ci
```

## 3. Ortam dosyasi

Ortak env dosyasini olustur:

```bash
mkdir -p /etc/eventra
cp .env.example /etc/eventra/eventra.env
```

Asagidaki alanlari host adreslerine gore duzenle:

```bash
KAFKA_BROKERS=127.0.0.1:9092
POSTGRES_URL=postgresql://eventra:eventra@127.0.0.1:5432/eventra
REDIS_URL=redis://127.0.0.1:6379
PORT=3001
CACHE_LOADER_PORT=3010
CACHE_LOADER_METADATA_DB_URL=postgresql://eventra:eventra@127.0.0.1:5432/eventra
RULE_ENGINE_HEALTH_PORT=3002
LLM_PROVIDER=mock
```

Frontend build icin gerekiyorsa:

```bash
APP_DOMAIN=www.example.com
API_DOMAIN=api.example.com
ACME_EMAIL=ops@example.com
```

## 4. Frontend build

```bash
cd /opt/eventra/current
VITE_API_BASE_URL=https://api.example.com npm --workspace @eventra/frontend run build
```

Static dosyalar:

```text
/opt/eventra/current/apps/frontend/dist
```

## 5. systemd unit dosyalari

Bu dizindeki unit dosyalarini hosta kopyala:

```bash
cp infra/unix/systemd/eventra-api.service /etc/systemd/system/
cp infra/unix/systemd/eventra-rule-engine.service /etc/systemd/system/
cp infra/unix/systemd/eventra-cache-loader.service /etc/systemd/system/
systemctl daemon-reload
```

## 6. Servisleri ayri ayri baslat

```bash
systemctl enable --now eventra-api
systemctl enable --now eventra-rule-engine
systemctl enable --now eventra-cache-loader
```

Durum:

```bash
systemctl status eventra-api --no-pager
systemctl status eventra-rule-engine --no-pager
systemctl status eventra-cache-loader --no-pager
```

Log:

```bash
journalctl -u eventra-api -f
journalctl -u eventra-rule-engine -f
journalctl -u eventra-cache-loader -f
```

Restart:

```bash
systemctl restart eventra-api
systemctl restart eventra-rule-engine
systemctl restart eventra-cache-loader
```

Stop:

```bash
systemctl stop eventra-api
systemctl stop eventra-rule-engine
systemctl stop eventra-cache-loader
```

## 7. Caddy

`infra/unix/Caddyfile` dosyasini kendi domainine gore duzenleyip `/etc/caddy/Caddyfile` olarak kopyala:

```bash
cp infra/unix/Caddyfile /etc/caddy/Caddyfile
caddy validate --config /etc/caddy/Caddyfile
systemctl restart caddy
```

## 8. Saglik kontrolleri

```bash
curl http://127.0.0.1:3001/health
curl http://127.0.0.1:3002/health
curl http://127.0.0.1:3010/health
curl -I https://www.example.com
curl https://api.example.com/health
```

## Notlar

- Bu modelde servisleri ayri ayri restart etmek kolaydir.
- `frontend` process olarak degil static site olarak servis edilir.
- Isteyen kurulumlarda `rule-engine` ve `cache-loader` ayri sunuculara da tasinabilir; sadece env adresleri degisir.
