import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data' show BytesBuilder;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// KampanyaBul sunucusu (LXC 101, Tailscale Funnel): güncel kampanyalar, giriş doğrulama, olay/hata logları.
/// Önce dış HTTPS adresi, olmazsa ev ağındaki doğrudan adres denenir.
class Sunucu {
  static const tabanlar = [
    'https://emlakdeal.tailb92005.ts.net/kampanyabul',
    'http://192.168.1.21:8791',
  ];
  static const surum = '0.5.1';

  static String? _cihaz;
  static String? _calisanTaban;

  /// Uygulamaya özel rastgele kimlik (reklam kimliği / donanım bilgisi değil).
  static Future<String> cihaz() async {
    if (_cihaz != null) return _cihaz!;
    final t = await SharedPreferences.getInstance();
    var c = t.getString('cihaz_id');
    if (c == null) {
      final r = Random.secure();
      c = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
      await t.setString('cihaz_id', c);
    }
    return _cihaz = c;
  }

  static Future<HttpClientResponse> _istek(
    String yontem,
    String yol, {
    Object? govde,
    Map<String, String> basliklar = const {},
    Duration sure = const Duration(seconds: 8),
  }) async {
    final sira = [if (_calisanTaban != null) _calisanTaban!, ...tabanlar.where((t) => t != _calisanTaban)];
    Object? sonHata;
    for (final taban in sira) {
      final hc = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      try {
        final rq = await hc.openUrl(yontem, Uri.parse('$taban$yol')).timeout(sure);
        rq.headers.set(HttpHeaders.acceptEncodingHeader, 'gzip');
        basliklar.forEach(rq.headers.set);
        if (govde != null) {
          // Python sunucusu parçalı (chunked) gövde okumaz: uzunluk açıkça verilmeli
          final b = utf8.encode(jsonEncode(govde));
          rq.headers.contentType = ContentType.json;
          rq.contentLength = b.length;
          rq.add(b);
        }
        final rs = await rq.close().timeout(sure);
        _calisanTaban = taban;
        return rs;
      } catch (e) {
        sonHata = e;
        hc.close(force: true);
      }
    }
    throw sonHata ?? StateError('sunucu yok');
  }

  static Future<Map<String, dynamic>?> _json(String yontem, String yol, Object? govde) async {
    try {
      final rs = await _istek(yontem, yol, govde: govde);
      final metin = await rs.transform(utf8.decoder).join();
      return jsonDecode(metin) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Sunucu $yol: $e');
      return null;
    }
  }

  /// Sunucu tarafında doğrulanmış giriş; sunucuya ulaşılamazsa null.
  static Future<Map<String, dynamic>?> giris(String saglayici, String token) async => _json('POST', '/api/giris', {
        'saglayici': saglayici,
        'token': token,
        'cihaz': await cihaz(),
        'surum': surum,
      });

  /// Hata/olay logu (beklemeden gönderilir, başarısızlık yutulur).
  static void olay(String tur, String ad, [Object? detay]) {
    unawaited(() async {
      var d = detay?.toString() ?? '';
      if (d.length > 4000) d = d.substring(0, 4000);
      await _json('POST', '/api/olay', {'cihaz': await cihaz(), 'tur': tur, 'ad': ad, 'detay': d, 'surum': surum});
    }());
  }

  /// Ham indirme (kart kataloğu, kart görseli); 304 / hata / ulaşılamazsa null.
  static Future<({List<int> veri, String? etag})?> indir(String yol, String? etag) async {
    try {
      final rs = await _istek('GET', yol,
          basliklar: {if (etag != null) HttpHeaders.ifNoneMatchHeader: etag}, sure: const Duration(seconds: 30));
      if (rs.statusCode != HttpStatus.ok) {
        await rs.drain<void>();
        return null;
      }
      final b = BytesBuilder(copy: false);
      await for (final p in rs) {
        b.add(p);
      }
      return (veri: b.takeBytes(), etag: rs.headers.value(HttpHeaders.etagHeader));
    } catch (e) {
      debugPrint('İndirilemedi $yol: $e');
      return null;
    }
  }

  /// Güncel kampanya JSON'u; değişmediyse (304) ya da ulaşılamazsa null.
  static Future<({String metin, String? etag})?> kampanyalar(String? etag) async {
    try {
      final rs = await _istek('GET', '/api/kampanyalar',
          basliklar: {if (etag != null) HttpHeaders.ifNoneMatchHeader: etag}, sure: const Duration(seconds: 40));
      if (rs.statusCode == HttpStatus.notModified) {
        await rs.drain<void>();
        return null;
      }
      if (rs.statusCode != HttpStatus.ok) {
        await rs.drain<void>();
        olay('hata', 'kampanya_indir', 'HTTP ${rs.statusCode}');
        return null;
      }
      final metin = await rs.transform(utf8.decoder).join();
      return (metin: metin, etag: rs.headers.value(HttpHeaders.etagHeader));
    } catch (e) {
      debugPrint('Kampanyalar indirilemedi: $e');
      return null;
    }
  }
}
