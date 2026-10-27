import 'package:flutter/services.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'sosyal_ayar.dart';
import 'sunucu.dart';

/// Giriş yapan kişinin profili (cihazda saklanır; giriş sunucuda doğrulanıp kaydedilir).
class Profil {
  final String ad;
  final String? eposta;
  final String? foto;
  final String saglayici; // google | facebook

  const Profil({required this.ad, this.eposta, this.foto, required this.saglayici});

  Map<String, dynamic> toJson() => {'ad': ad, 'eposta': eposta, 'foto': foto, 'saglayici': saglayici};

  factory Profil.fromJson(Map<String, dynamic> j) => Profil(
        ad: j['ad'] as String,
        eposta: j['eposta'] as String?,
        foto: j['foto'] as String?,
        saglayici: j['saglayici'] as String,
      );

  String get bas => ad.trim().isEmpty ? '?' : ad.trim().substring(0, 1).toUpperCase();
  String get saglayiciAdi => saglayici == 'google' ? 'Google' : 'Facebook';
}

/// Sonuç: profil ya da kullanıcıya gösterilecek hata (iptal → ikisi de null).
typedef GirisSonucu = ({Profil? profil, String? hata});

/// Google / Facebook girişi. Sağlayıcı token'ı sunucuda doğrulanır ve kaydedilir;
/// sunucuya ulaşılamazsa giriş cihazdaki profille devam eder. Her adım sunucu loguna düşer.
class SosyalGiris {
  static Profil _sunucuProfili(Map<String, dynamic>? r, Profil yerel, String saglayici) {
    if (r == null) {
      Sunucu.olay('hata', 'giris_${saglayici}_sunucu', 'sunucuya ulaşılamadı');
      return yerel;
    }
    final k = r['kullanici'];
    if (r['ok'] != true || k is! Map) {
      Sunucu.olay('hata', 'giris_${saglayici}_red', r['hata'] ?? r);
      return yerel;
    }
    return Profil(
      ad: (k['ad'] as String?) ?? yerel.ad,
      eposta: (k['eposta'] as String?) ?? yerel.eposta,
      foto: (k['foto'] as String?) ?? yerel.foto,
      saglayici: saglayici,
    );
  }

  static Future<GirisSonucu> google() async {
    try {
      final g = GoogleSignIn(scopes: const ['email'], serverClientId: googleSunucuIstemci);
      await g.signOut(); // her seferinde hesap seçici çıksın
      final a = await g.signIn();
      if (a == null) {
        Sunucu.olay('olay', 'giris_google_iptal');
        return (profil: null, hata: null);
      }
      final yerel = Profil(ad: a.displayName ?? a.email.split('@').first, eposta: a.email, foto: a.photoUrl, saglayici: 'google');
      final idToken = (await a.authentication).idToken;
      if (idToken == null) {
        Sunucu.olay('hata', 'giris_google', 'idToken yok');
        return (profil: yerel, hata: null);
      }
      return (profil: _sunucuProfili(await Sunucu.giris('google', idToken), yerel, 'google'), hata: null);
    } on PlatformException catch (e) {
      Sunucu.olay('hata', 'giris_google', '${e.code}: ${e.message}');
      // ApiException 10 = bu paket + imza (SHA-1) Google Cloud'da tanımlı değil
      if ((e.message ?? "").contains(" 10") || (e.message ?? "").startsWith("10")) {
        return (profil: null, hata: 'Google girişi henüz etkin değil (Google Cloud\'da Android istemcisi tanımlanmalı).');
      }
      return (profil: null, hata: 'Google girişi başarısız: ${e.message ?? e.code}');
    } catch (e) {
      Sunucu.olay('hata', 'giris_google', e);
      return (profil: null, hata: 'Google girişi başarısız: $e');
    }
  }

  static Future<GirisSonucu> facebook() async {
    try {
      final r = await FacebookAuth.instance.login(permissions: const ['public_profile']);
      if (r.status == LoginStatus.cancelled) {
        Sunucu.olay('olay', 'giris_facebook_iptal');
        return (profil: null, hata: null);
      }
      if (r.status != LoginStatus.success) {
        Sunucu.olay('hata', 'giris_facebook', '${r.status.name}: ${r.message}');
        return (profil: null, hata: 'Facebook girişi başarısız: ${r.message ?? r.status.name}');
      }
      final u = await FacebookAuth.instance.getUserData(fields: 'name,picture.width(240)');
      final foto = ((u['picture'] as Map?)?['data'] as Map?)?['url'] as String?;
      final yerel = Profil(ad: (u['name'] as String?) ?? 'Facebook kullanıcısı', foto: foto, saglayici: 'facebook');
      final token = r.accessToken?.tokenString;
      if (token == null) {
        Sunucu.olay('hata', 'giris_facebook', 'token yok');
        return (profil: yerel, hata: null);
      }
      return (profil: _sunucuProfili(await Sunucu.giris('facebook', token), yerel, 'facebook'), hata: null);
    } catch (e) {
      Sunucu.olay('hata', 'giris_facebook', e);
      return (profil: null, hata: 'Facebook girişi başarısız: $e');
    }
  }

  static Future<void> cikis(String saglayici) async {
    Sunucu.olay('olay', 'cikis_$saglayici');
    try {
      if (saglayici == 'google') await GoogleSignIn().signOut();
      if (saglayici == 'facebook') await FacebookAuth.instance.logOut();
    } catch (_) {}
  }
}
