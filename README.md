# KampanyaBul

Türkiye'deki ~20 banka ve cüzdanın kredi kartı kampanyalarını tek yerde gösteren Flutter uygulaması
(Android + iOS). Kampanya verisi, kampanya görselleri, kart kataloğu ve kategori görselleri sunucudan gelir;
görsel/veri değişikliği için yeniden kurulum gerekmez.

## iOS'ta derleme (Mac)

Gerekenler: Xcode, CocoaPods (`sudo gem install cocoapods` ya da `brew install cocoapods`), Flutter.

```bash
git clone https://github.com/sonerooz/kampanyabul.git
cd kampanyabul

# 1) Facebook istemci token'ı (depoda yok)
cp ios/Flutter/Sosyal.xcconfig.ornek ios/Flutter/Sosyal.xcconfig
#    FACEBOOK_CLIENT_TOKEN değerini doldur:
#    developers.facebook.com → Emlak Deal → Ayarlar → Gelişmiş → İstemci tokeni

# 2) bağımlılıklar
flutter pub get
cd ios && pod install && cd ..

# 3) imzalama: Xcode'da aç → Runner → Signing & Capabilities → Team seç
open ios/Runner.xcworkspace

# 4) iPhone'u kabloyla bağla (Ayarlar → Gizlilik → Geliştirici Modu açık olmalı)
flutter run --release
```

Ücretsiz Apple hesabıyla imzalanan uygulama 7 gün çalışır, sonra yeniden `flutter run` gerekir.

## Giriş ayarları

- **Google:** iOS OAuth istemcisi `Info.plist` içinde (`GIDClientID` + ters şema). İzin ekranı test modunda;
  yalnız test kullanıcıları girebilir.
- **Facebook:** Emlak Deal FB uygulaması (4633869850195321). iOS paket kimliği `com.soner.kampanyabul`
  FB uygulamasının iOS platformuna eklenmiş olmalı.

## Android

```bash
flutter build apk --release --split-per-abi
```

`android/sosyal.properties` (depoda yok) Facebook kimliklerini içerir:

```
facebook_app_id=4633869850195321
facebook_client_token=...
```
