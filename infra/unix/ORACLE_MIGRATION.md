# Oracle Deployment Notes

Bu repo Oracle ana veritabani ile calisacak sekilde duzenlenmistir.

Temel noktalar:
- Ana uygulama veritabani Oracle'dir.
- Cache loader metadata veritabani da Oracle'dir.
- Otomatik tablo olusturma yoktur; DDL manuel uygulanir.
- Gerekli tum create scriptleri `oracle-schema.sql` dosyasindadir.
- Temel smoke test sorgulari `oracle-smoke-test.sql` dosyasindadir.

Calistirma sirasi:
1. `infra/unix/oracle-schema.sql` uygula
2. `infra/unix/oracle-smoke-test.sql` veya `infra/unix/run-oracle-smoke.sh` ile kontrol et
3. `api`, `rule-engine`, `cache-loader` servislerini systemd ile baslat

Hedef state:
- Host uzerinde Oracle / Redis / Kafka
- `api`, `rule-engine`, `cache-loader` ayri `systemd` servisleri
- `frontend` static build + `caddy`
- Her servis ayri `start/stop/restart` ile yonetilebilir
