# Eventra MVP Bootstrap

Bu repo, EVAM benzeri bir urun icin ilk MVP iskeletini kurar.

## Icerik

- Kafka event ingestion
- API (`apps/api`) ile event alma ve persist etme
- Basit rule engine (`services/rule-engine`) ile `cart_add -> email action` tetikleme
- Redis customer son durum cache'i
- Postgres kalici veri
- React Flow journey designer (`apps/frontend`)

## Local Baslatma

Bu repo artik Docker/Podman merkezli degil. Gelistirme ve deploy akisi, ayri servisler ve host servisleri uzerinden ilerler.

Gerekli host servisleri:

- PostgreSQL
- Redis
- Kafka

1. Paketleri yukle:

```bash
npm install
```

2. Ortam degiskenlerini hazirla:

```bash
cp .env.example .env
```

3. Host servis adreslerini `.env` icinde duzenle:

```bash
KAFKA_BROKERS=127.0.0.1:9092
POSTGRES_URL=postgresql://eventra:eventra@127.0.0.1:5432/eventra
REDIS_URL=redis://127.0.0.1:6379
```

4. Servisleri ayri terminallerde calistir:

```bash
npm run dev:api
npm run dev:rule-engine
npm run dev:cache-loader
npm run dev:frontend
```

Beklenen local adresler:
- Frontend: `http://localhost:3000`
- API: `http://localhost:3001`
- Rule engine health: `http://localhost:3002/health`
- Cache loader: `http://localhost:3010`

Saglik kontrolleri:

```bash
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3010/health
```

## Unix Deployment (Container'siz)

Docker/Podman kullanmadan klasik Unix sunucuda ayri servisler olarak calistirmak icin hazir iskelet:

- dokuman: [infra/unix/README.md](infra/unix/README.md)
- `systemd` unitleri:
  - [infra/unix/systemd/eventra-api.service](infra/unix/systemd/eventra-api.service)
  - [infra/unix/systemd/eventra-rule-engine.service](infra/unix/systemd/eventra-rule-engine.service)
  - [infra/unix/systemd/eventra-cache-loader.service](infra/unix/systemd/eventra-cache-loader.service)
- Caddy config:
  - [infra/unix/Caddyfile](infra/unix/Caddyfile)

Bu modelde:

- `api`, `rule-engine`, `cache-loader` ayri `systemd` servisleri olarak calisir
- `frontend` static build olarak `caddy` ile servis edilir
- `postgres`, `redis`, `kafka` host servisleri olur

Bu sayede su komutlar dogrudan mumkun olur:

```bash
systemctl start eventra-api
systemctl stop eventra-api
systemctl restart eventra-rule-engine
systemctl status eventra-cache-loader --no-pager
```


## Ornek Event Gonderimi

```bash
curl -X POST http://localhost:3001/ingest \
  -H 'content-type: application/json' \
  -d '{
    "customer_id":"cust-123",
    "event_type":"cart_add",
    "payload":{"product_id":"p-42","price":1499},
    "source":"web"
  }'
```

Bu event `event.raw` topic'ine gider. Rule engine kurala uyarsa `action_log` tablosuna kayit atar ve `action.triggered` topic'ine aksiyon yazar.

## Cache Loader (Ayrı Uygulama)

`apps/cache-loader` ayrı bir scheduler uygulamasıdır.

Amac:
- Dış DB'ye `SELECT` query çalıştırmak
- Sonucu Redis cache dataset olarak yazmak
- Günlük belirlenen saatte otomatik çalıştırmak (örn: `07:00`)

UI:
- `http://localhost:3010`

Akış:
1. Connection ekle (host/port/db/user/pass)
2. Job ekle:
   - `dataset_key`
   - `sql_query` (sadece SELECT)
   - `key_column`
   - `run_time` (`HH:mm`)
   - `timezone` (örn `Europe/Istanbul`)
3. `Run Now` ile manuel test et
4. Scheduler her gün belirtilen saatte otomatik çalıştırır

Redis yazımı:
- Hash: `cache:dataset:{dataset_key}`
- Meta: `cache:dataset:{dataset_key}:meta`
- Pub/Sub: `cache.updated`

## Journey API

Journey listesi:

```bash
curl http://localhost:3001/journeys
```

Journey publish/update:

```bash
curl -X POST http://localhost:3001/journeys \
  -H 'content-type: application/json' \
  -d '{
    "journey_id":"cart_abandonment_v1",
    "version":1,
    "name":"Cart Abandonment 30m",
    "status":"published",
    "graph_json":{"nodes":[{"id":"trigger","type":"trigger"},{"id":"wait","type":"wait"}]}
  }'
```

Journey instance listesi:

```bash
curl "http://localhost:3001/journey-instances?customer_id=cust-123&limit=10"
```

## Branching Condition (True/False Edge)

- Frontend'de condition node'dan cikan edge'i sec.
- Sag panelde `Condition Branch` alanini `true` veya `false` yap.
- Rule engine bu label/data bilgisini okuyup ilgili action path'ine gider.

## Customer Profile API (segment_match)

Profil set et:

```bash
curl -X PUT http://localhost:3001/customers/cust-123/profile \
  -H 'content-type: application/json' \
  -d '{"segment":"vip","attributes":{"tier":3}}'
```

Profil getir:

```bash
curl http://localhost:3001/customers/cust-123/profile
```

- Condition node'da `condition_key = segment_match` sec.
- `condition_segment_value` alanina segment adi yaz (ornek: `vip`).

## Email Delivery (SMTP)

`.env` icine SMTP bilgilerini ekle:

```bash
SMTP_HOST=smtp.example.com
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=your_user
SMTP_PASS=your_pass
SMTP_FROM="Eventra <no-reply@yourdomain.com>"
EMAIL_DRY_RUN=false
```

Customer profile'da email tut:

```bash
curl -X PUT http://localhost:3001/customers/cust-123/profile \
  -H 'content-type: application/json' \
  -d '{"segment":"vip","attributes":{"email":"customer@example.com"}}'
```

- Journey action node `channel=email` oldugunda worker SMTP ile gondermeyi dener.
- Sonuc `action_log.status` alanina `sent` veya `failed` olarak yazar.

## Production Deployment

Production hedef modeli:

- host uzerinde PostgreSQL / Redis / Kafka
- `systemd` ile `api`, `rule-engine`, `cache-loader`
- `caddy` ile static frontend + API reverse proxy

Detayli kurulum:

- [infra/unix/README.md](infra/unix/README.md)
