# Eventra Bruno Collection

Bu koleksiyon local Podman stack icin hazirlandi.

Kullanim:
- Bruno icine `Eventra-Local.zip` dosyasini import et
- `local` environment sec
- Gerekirse once `environments/local.bru` icindeki degiskenleri guncelle

En onemli degiskenler:
- `apiBaseUrl`
- `cacheLoaderBaseUrl`
- `customerId`
- `journeyId`
- `connectionId`
- `jobId`

Onerilen ilk akış:
1. API/Core/Health
2. API/Customers/Upsert Customer Profile
3. API/Journeys/Create Or Update Journey
4. API/Core/Ingest Event
5. API/Operational/List Journey Instances
6. Cache Loader/Health
