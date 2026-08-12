---
name: send-media-to-telegram
description: Send files via MEDIA tag. Use when Hasan yolla diyorsa.
version: 1.1.0
platforms: [windows]
metadata:
  hermes:
    tags: [telegram, media, file-send]
    category: communication
    related_skills: []
---

# Telegram'da Dosya Gönderme (Hermes)

## When to Use

Hasan bir dosyayı göndermeni istediğinde ("gönder", "at", "yolla", "mp3 yapıp at", "şarkıyı yolla" vb.) ve önceki adımlarda bir dosya üretilmişse, depolanmışsa, indirilmişse bu skill'i uygula.

Amaç: küçük dosyayı Telegram eki olarak, limit aşan dosyayı ise doğrulanmış geçici indirme bağlantısıyla kullanıcıya ulaştırmak — ses balonu (voice bubble) olarak değil, standart indirilebilir dosya olarak.

## Temel Kural

`text_to_speech` tool'u dosyanın üzerine yazabilir ve voice bubble üretir; dosya tesliminde kullanma. Dosya 45 MB veya altındaysa düz `MEDIA:` etiketi, daha büyükse doğrulanmış tmpfiles.org fallback'i kullan.

## Adımlar

1. **Önce dosyayı doğrula.** `stat` ile boyutu, `sha256sum` ile bütünlüğü kontrol et. Eğer `text_to_speech` daha önce aynı yola yazmışsa, orijinali başka bir konumdan (Masaüstü, Downloads vb.) geri kopyala.
2. **Boyut sınırını ölç.** Telegram bot API 50 MB üzeri medyayı keser; güvenli doğrudan gönderim eşiği 45 MB'tır. Telegram medya kökü: `C:\Users\ben\AppData\Local\hermes\comfy_outputs`.
3. **Dosya 45 MB veya altındaysa doğrudan gönder.** Native Windows path kullan; MSYS `/c/Users/ben/...` bazı tool'larda "No such file" verir.

   ```
   MEDIA:C:\Users\ben\AppData\Local\hermes\comfy_outputs\dosya.mp3
   ```

   `[[audio_as_voice]]` öneki ekleme. Yalnız gerçek TTS ses balonu gerektiğinde kullanılır.
4. **Dosya 45 MB'ı aşıyorsa tmpfiles.org fallback'ini kullan.** Kullanıcı dosyayı göndermeni istediği için bu istek, dosyanın geçici üçüncü taraf barındırmaya yüklenmesine açık yetki sayılır; ayrıca tekrar onay isteme. Gizli anahtar, özel sağlık verisi dökümü veya kullanıcının paylaşılmasını istemediği içerik varsa otomatik yükleme yapma ve güvenli alternatif sor.

   ```bash
   curl --fail --show-error --silent --max-time 600 \
     -F "file=@C:\\DOSYA\\YOLU;filename=DOSYA_ADI" \
     https://tmpfiles.org/api/v1/upload
   ```

5. **API yanıtını doğrula.** Yanıt `status=success` ve `data.url` içermeli. Sayfa URL'sini kullanıcıya nihai indirme linki diye vermeden önce sayfayı GET et; `a.download` bağlantısındaki gerçek süreli URL'yi çıkar. Yeni tmpfiles sürümleri basit `/dl/{id}/{name}` yolunu tekrar sayfaya yönlendirebilir; gerçek bağlantı `/dl/{timestamp.token}/{id}/{name}` biçiminde olabilir.
6. **Dosya imzasını doğrula.** Gerçek süreli URL'den `Range: bytes=0-1023` ile ilk 1 KB'ı indir. APK/ZIP için ilk iki bayt `PK`, görsel/ses için beklenen magic-byte veya MIME türü görülmeden linki gönderme. Dosyanın yerel SHA-256 değerini ve boyutunu da kullanıcıya yaz.
7. **Süreyi açıkça belirt.** tmpfiles sayfasındaki `File expires in ...` değerini çıkar ve bağlantının geçici olduğunu söyle. Süre görünmüyorsa “geçici bağlantı” de; süre uydurma.
8. **Doğrulanmış gerçek indirme URL'sini gönder.** Kullanıcıdan indirmenin başladığını veya dosyanın ulaştığını teyit et. tmpfiles yükleme/indirme doğrulaması başarısızsa aynı bozuk linki paylaşma; 45 MB parçalama veya onaylı başka barındırma seçeneğine dön.

## Pitfalls

- **`text_to_speech` çağırırsan hedef dosyanın üzerine yazar** ve sadece 10 KB civarı TTS MP3 kalır. Önce kontrol et, sonra gönder.
- **Voice bubble ile şarkı gönderme** — Hasan "şarkıyı gönder" dediğinde standart dosya eki ister, ses kaydı sesi değil.
- **MSYS path** bazen ffmpeg/ytdlp gibi Windows native exe'lerde "No such file" hatası verir. Dosya üzerinde shell işlemi yapıyorsan `C:\Users\ben\...` formunu kullan.
- **MEDIA tetikleyicisi bazen kullanıcı tarafına ulaşmaz.** Önce `ls -la` ile dosyanın var olduğunu doğrula, sonra gönder; iki kez deneyip ikisinde de gelmediyse kullanıcıya haber ver ve dosyanın konumunu (Masaüstü vb.) bildir.
- **Telegram 50 MB sınırı** — 45 MB üzerini doğrudan `MEDIA:` ile deneme; varsayılan fallback tmpfiles.org yüklemesidir. tmpfiles başarısızsa 45 MB parçalara böl.
- **tmpfiles sayfa URL'si doğrudan dosya olmayabilir** — API'nin döndürdüğü `data.url` çoğu zaman HTML indirme sayfasıdır. Sayfadaki `a.download` href'ini çıkar ve yalnız Range probe ile gerçek dosya imzası doğrulandıktan sonra gönder.
- **HEAD isteğine güvenme** — tmpfiles HEAD veya kısa `/dl/` yolu HTML sayfasına yönlenebilir. Gerçek URL'yi GET + HTML ayrıştırma ile bul; ilk baytları Range GET ile doğrula.
- **Süreli bağlantıyı kalıcı gibi sunma** — sayfadaki kalan süreyi kullanıcıya yaz ve indirmeyi geciktirmemesini belirt.
- **Hassas dosyaları otomatik üçüncü tarafa yükleme** — gizli anahtarlar, kimlik bilgileri, özel sağlık dökümleri ve açıkça paylaşılmaması istenen içerik için güvenli yerel/parçalı teslim kullan.

## Doğrulama

- Doğrudan Telegram gönderiminde kullanıcı “geldi” derse tamam.
- tmpfiles fallback'inde şu dört kanıt birlikte bulunmalı: API `status=success`, sayfadan çıkarılmış gerçek indirme URL'si, Range probe ile doğru dosya magic-byte'ı ve yerel SHA-256/boyut.
- Kullanıcı linki açıp indirmeyi başlatabildiğini teyit ederse teslim tamamdır.
- `MEDIA:` gelmediyse aynı direktifi tekrar tekrar yollama: platform/gateway uyarılarını kontrol et, dosyayı izinli medya köküne taşı; limit aşımı varsa tmpfiles fallback'ine geç.
- tmpfiles linki süresi dolduysa dosyayı yeniden yükle; eski URL'yi tekrar paylaşma.

## Referans Akış (somut)

```bash
# 1. Dosyayı doğrula
stat -c '%s bytes' 'C:\DOSYA\uygulama.apk'
sha256sum 'C:\DOSYA\uygulama.apk'

# 2a. <=45 MB ise doğrudan Telegram
# MEDIA:C:\Users\ben\AppData\Local\hermes\comfy_outputs\uygulama.apk

# 2b. >45 MB ise tmpfiles API
curl --fail --show-error --silent --max-time 600 \
  -F "file=@C:\\DOSYA\\uygulama.apk;filename=uygulama.apk" \
  https://tmpfiles.org/api/v1/upload

# 3. data.url sayfasındaki a.download href'ini çıkar.
# 4. Gerçek URL'yi Range GET ile doğrula; APK/ZIP ilk baytları PK olmalı.
curl --fail --silent --show-error --range 0-1023 -o probe.bin 'GERCEK_INDIRME_URL'
```

## Tarihçe

- 1 Ağustos 2026: 45 MB üzeri dosyalarda varsayılan tmpfiles.org fallback'i, gerçek süreli URL ayrıştırma, Range magic-byte doğrulaması, SHA-256/boyut raporu ve hassas dosya istisnası eklendi.
- 31 Temmuz 2026: Hasan "şarkıyı gönder" dedi. Önce `text_to_speech` denemiştim, hem dosyayı ezip hem voice bubble yollamış. Doğru yöntem düz "MEDIA:" tag'i.
