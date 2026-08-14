# AGENTS.md — Kodmoz Notebook Mobile

> **Bu dosya, bu projeyi ilk kez açan her agent (Aura dahil) için.**
> Hangi skilleri yüklemeli, hangi dosyalara bakmalı, hangi tuzaklardan
> kaçınmalı — hepsi burada.

## Sen kimsin

Bu projede çalışan bir AI kodlama asistanısın. Kullanıcın Hasan'dır.
Türkçe yanıt ver, kısa ve OK/FAIL formatında (Hasan'ın talebi).

## İlk yapman gereken: skilleri yükle

Hermes ortamındaysan, çalışmaya başlamadan önce şu üç skill'i
`skill_view(name=...)` ile yükle:

1. **`kodmoz-notebook-mobile`** — bu proje için özelleştirilmiş playbook.
   API surface, dosya haritası, manifest tuzakları, build adımları.
2. **`kodmoz-flutter-mobile`** — Flutter-on-Kodmoz'un genel kuralları
   (PATH, `flutter clean` migration davranışı, iOS bundle teslimi).
3. **`kodmoz-open-notebook-operations`** — backend'in kendisi. Pod
   kontrolü, secret çekme, SurrealDB sorgulama.

Üçünü de yükledikten sonra `docs/README.md` reading order'a göre ilerle.

## Proje özeti

| | |
|---|---|
| **Path** | `/home/ben/kodmoz\mobile\kodmoz_notebook\` |
| **Dil** | Dart + Flutter 3.44.8 |
| **Hedef** | Android, iOS, macOS, Linux, Windows, Web |
| **Backend** | `https://notebook.kodmoz.com/api` (Open Notebook, FastAPI + SurrealDB) |
| **Auth** | Tek bearer token, k8s secret `open-notebook-secrets` / `app-password` = `Kodmoz!!2026!!` |
| **Mevcut sürüm** | v1.0.1 (Android APK, çalışıyor) |

## Döküman haritası

```
docs/
├── README.md                        ← okumaya buradan başla
├── architecture/
│   ├── overview.md                  ← 3 katmanlı mimari
│   ├── data-model.md                ← SurrealDB tabloları (çıkarım)
│   └── auth.md                      ← bearer token modeli
├── api/
│   ├── README.md                    ← mobilin kullandığı endpoint altkümesi
│   ├── endpoints.md                 ← 95 route'un tam listesi
│   └── models.md                    ← 60 Pydantic model, field-by-field
└── operations/
    ├── build-and-deploy.md          ← platform build komutları
    ├── local-verified-facts.md      ← 12 Ağustos 2026 canlı yanıt şekilleri
    └── known-bugs.md                ← 6 bug + workaround (v1.0.1 fix dahil)
```

## Sık yapılan görevler

### 1. APK derle ve Hasan'a gönder

```bash
cd /c/Kodmoz/mobile/kodmoz_notebook
flutter analyze && flutter test
dart run test/integration_smoke.dart   # tüm 7 endpoint OK olmalı
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

APK >45 MB → `send-media-to-telegram` skill'indeki tmpfiles.org
fallback'iyle gönder. SHA-256'yı mutlaka ekle.

### 2. Yeni bir ekran ekle

- `lib/models/` altına yeni bir kaynak varsa model ekle (fromJson/toJson).
- `lib/api/api_client.dart` içine yeni endpoint method'u ekle.
- `lib/screens/` altında `StatefulWidget + Future<_Data> + RefreshIndicator`
  formunda yeni ekran. Konvansiyon: parent `_RootShell`'in
  `widget.api`'sini `final api: ApiClient` parametresi olarak al.
- Bottom tab'a eklemek için `lib/main.dart` `_RootShell`'de hem
  `pages` listesini hem de `NavigationBar.destinations`'ı güncelle.
- Mevcut `widgets/status_badge.dart` paletini kullan, yeni status yoksa
  palette'e ekle.

### 3. Backend API şeması değişti

1. `dart run test/integration_smoke.dart` çalıştır, hangi endpoint
   kırıldığını gör.
2. İlgili model'in `fromJson`'unu güncelle.
3. İlgili ekranı düzelt (büyük ihtimal yeni bir alan gösteriliyordur).
4. `docs/operations/local-verified-facts.md`'ye yeni gözlemi ekle.

### 4. APK telefon açılmıyor / crash ediyor

İlk olarak merged manifest'i kontrol et:
```bash
"/c/Program Files/PowerShell/7/pwsh.exe" -Command "& 'C:\Android\sdk\build-tools\36.0.0\aapt.exe' dump xmltree build/app/outputs/flutter-apk/app-release.apk AndroidManifest.xml"
```
- `<application android:name="io.flutter.embedding.android.FlutterApplication">`
  → doğru. Başka bir şeyse Flutter engine başlamıyordur.
- `MainActivity` doğru package'te mi? Manifest'teki `activity/android:name`
  ile `MainActivity.kt`'nin `package` satırı eşleşmeli.
- `minSdkVersion` telefonun Android sürümünden büyük mü?

`docs/operations/known-bugs.md` §6 tam bu senaryoyu anlatıyor (v1.0.0
→ v1.0.1 fix'i).

## Yapma listesi

- **Asla** `android:name="${applicationName}"` placeholder'ına
  güvenme — Flutter 3.44 manifest merger'ı bunu `android.app.Application`'a
  düşürebilir. Açıkça `io.flutter.embedding.android.FlutterApplication` yaz.
- **Asla** Flutter Gradle Plugin'in "Upgrading build.gradle.kts" çıktısına
  güvenme — kendi `minSdk = 23` ayarını geri çevirebilir. Her build'den
  sonra kontrol et.
- **Asla** gerçek API token'ı koda göm — login screen'den alınsın,
  `SharedPreferences`'ta saklansın. Test smoke scriptinde kullanılan
  değer (`Kodmoz!!2026!!`) sadece lokal geliştirme içindir.
- **Asla** `flutter_secure_storage: ^9.2.4` ekleme — `compileSdk 34`
  hardcoded, bu build host'ta yok. Skill'in `kodmoz-flutter-mobile`
  Pitfall #10'una bak.

## Test stratejisi

- **Lint:** `flutter analyze` → 0 issues (CI gate)
- **Unit:** `flutter test` → 1/1 (splash load)
- **Smoke:** `dart run test/integration_smoke.dart` → ALL OK (live API)
- **Manual:** APK'yı telefona kur, login → home → notes → sources →
  chat → settings akışının hepsi sorunsuz açılmalı.
- **Manifest:** Her release build'den sonra
  `aapt dump xmltree app-release.apk AndroidManifest.xml` çalıştır ve
  `FlutterApplication` doğru class olarak doğrula.

## Kod stili

- 2-space indent (Flutter default).
- Single quotes string literals için (lint bunu zorunlu tutmaz ama
  repo standardı bu).
- `print()` sadece test/smoke scriptlerinde. Uygulama kodunda asla.
- `_` isimlendirmesi private members için (Dart underscore convention).
- `// ignore_for_file: ...` yorumu sadece test dosyalarında
  (`integration_smoke.dart`).
