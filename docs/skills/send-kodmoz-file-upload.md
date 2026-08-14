---
name: send-kodmoz-file-upload
description: Use when sending files with a link via send.kodmoz.com.
---

# send.kodmoz.com dosya yükleme

Hasan dosya göndermek istediğinde (veya link atılması gerektiğinde) send.kodmoz.com kullanılır. Web UI yerine API ile curl'dan yüklenir.

## Önemli gerçekler
- Uygulama: timvisee/send (Firefox Send fork), k3s `send` namespace'inde
- İmaj: `ke-registry:5000/kodmoz/send-r2:1.0.3` (S3 prefix destekli özel build; upstream `registry.gitlab.com/timvisee/send:latest`'ten türetildi — `server/config.js`'e `S3_PREFIX` env'i, `server/storage/s3.js`'e prefix'li key eklendi). NOT: eski özel build `ke-registry:5000/kodmoz/send-anon:1.0.5` Redis 7 ile `HSET invalid argument type` hatası veriyordu (500) — artık kullanılmıyor. Deploy yaml: `/home/ben/kodmoz\Send\deploy\k8s\send.yaml`
- Varsayılan süre: 24s (86400s), indirme limiti: 1 — isteğe göre `expires`/`downloads` metadata'da değiştirilir (MAX: 604800s / 100)
- Maks. dosya boyutu: `MAX_FILE_SIZE` env'i (byte) — şu an 300 MiB (314572800). Değiştir: `kubectl -n send set env deploy/send MAX_FILE_SIZE=<bytes>` + `/home/ben/kodmoz\Send\deploy\k8s\send.yaml` güncelle. Doğrula: `curl -sS https://send.kodmoz.com/ | grep -o 'MAX_FILE_SIZE":[0-9]*'` (SPA LIMITS bloğunda görünür). Not: site Cloudflare arkasındaysa free plan 100 MB edge limiti uygular — 100MB+ upload 413 alırsa CF tarafı.
- Toplam kota: `QUOTA_BYTES` env'i (byte) — şu an **1 GiB (1073741824)**. 0 = devre dışı. Özel build `send-r2:1.0.2`'de HTTP upload'a uygulandı: upload route'u Redis'teki dosyaların `byteSize` alanları toplamını + yeni dosyanın `Content-Length`'ini kota ile karşılaştırır, aşarsa 413. **`send-r2:1.0.3`'te WebSocket yolu da kapatıldı** (web UI upload'ı HTTP değil WS `/api/ws` üzerinden yapar; WS'te Content-Length olmadığı için kota 1.0.2'de atlanıyordu — reproduce: chunked/WS upload 2MB → 200): ws.js'te (a) client `fileInfo.size` bildirirse `encryptedSize(plain)` ile dosya akmadan ön kontrol 413, (b) size bildirmeyen istemciler için stream üzerinden `byteSize` ölçülür, storage.set sonrası kota aşımında `storage.del(id)` (R2+Redis) + 413. `byteSize` upload sırasında server-side ölçülür (web UI şifreli metadata gönderdiği için metadata'dan boyut çıkarılamaz). Eski JSON metadata'lı dosyalar `size` alanından, şifreli olanlar byteSize yoksa 0 sayılır. Değiştir: `kubectl -n send set env deploy/send QUOTA_BYTES=<bytes>` + yaml (yaml'daki değeri canlıdan koparma — 2026-08-07'de yaml 1 GiB iken canlı 1 MiB idi). İmaj build notu: upload.js + ws.js + quota.js + config.js'e patch → `docker run -d <eski-imaj> sleep 3600` → `docker cp` → `docker commit --change 'CMD ["node", "server/bin/prod.js"]'` → `k3d image import -c ke-cluster` → registry push: `docker tag ke-registry:5000/kodmoz/send-r2:<tag> registry.kodmoz.com/kodmoz/send-r2:<tag> && docker push`. Kaynak patch'ler: `/home/ben/kodmoz\Send\quota-patch\` (upload.js, ws.js, quota.js, config.js). Ortak helper: `server/routes/quota.js` (getUsedBytes).

## Yükleme komutu (çalışan formül)
```bash
SIZE=$(stat -c%s "$FILE")
META=$(python -c "import json,sys; print(json.dumps({'name':'<filename>','size':$SIZE,'downloads':1,'expires':86400}))")
curl -sS -m 90 -X POST https://send.kodmoz.com/api/upload \
  -H "X-File-Metadata: $META" \
  -H "Authorization: send-v1 <random-key>" \
  --data-binary @"$FILE"
```
Cevap: `{"url":"https://send.kodmoz.com/download/<id>/","owner":"...","id":"..."}` → kullanıcıya `url` verilir.

## Pitfall'lar
- **API multipart DEĞİL** — header tabanlı: `X-File-Metadata` (JSON string) + `Authorization: send-v1 <key>` gerekli, body ham dosya. Eksikse 400 Bad Request.
- **MSYS path sorunu:** curl Windows native binary olduğu için `/tmp/...` gibi MSYS yollarını açamaz (`Failed to open/read local data`). `--data-binary @"C:/Users/ben/..."` (Windows path, forward slash) kullan.
- Multipart `-F "file=@..."` çalışmaz (500/400) — doğru format yukarıdaki header'lı POST.
- 500 görürsen: pod log kontrol et (`kubectl logs -n send deploy/send --tail=30`). Redis HSET hatası dönerse imaj upstream'e dönmüş demektir (yukarıdaki not).
- Upload sonrası dosyayı lokalden sil (`rm -f`), test dosyalarını bırakma.

## Doğrulama
```bash
curl -sS -o /dev/null -w "%{http_code}\n" "https://send.kodmoz.com/download/<id>/"  # 200 beklenir
```

## Diğer bilgiler
- Dosya depolama: **Cloudflare R2 bucket `drive`, klasör `send.kodmoz.com/`** (S3 storage, key: `send.kodmoz.com/1-<id>`). Metadata Redis (`send-redis`, 7.4-alpine, **emptyDir** — kalıcı volume yok, pod restart'ta eski linkler ölür).
- S3 env'leri: `S3_BUCKET=drive`, `S3_PREFIX=send.kodmoz.com`, `S3_ENDPOINT=https://<account_id>.r2.cloudflarestorage.com`, `S3_USE_PATH_STYLE_ENDPOINT=true`; R2 credential'ları Secret `send-r2` (namespace send) → `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY`.
- Kaynak: `/home/ben/kodmoz\Send\src` geçici clone'du, silindi. Yeniden build gerekirse: clone timvisee/send → config.js + s3.js'e S3_PREFIX patch'le → `docker commit --change 'CMD ["node", "server/bin/prod.js"]'` ile imaj üret (Docker Desktop credential helper Session 0'da çalışmaz, base pull/build etme; mevcut upstream imajından container başlatıp dosya kopyala+commit et) → `k3d image import -c ke-cluster`.
- BASE_URL: https://send.kodmoz.com, Cloudflare üzerinden, Traefik IngressRoute, TLS `kodmoz-tailnet-tls`
