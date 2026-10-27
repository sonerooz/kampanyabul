import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../sunucu.dart';
import 'model.dart';

/// Kampanya verisinin nereden geldiğini soyutlar.
///
/// Şimdilik yalnız [AssetVeriKaynagi] var (APK'ya gömülü JSON). İleride LXC 101
/// sunucusundan güncel JSON çekmek için aynı arayüzle bir `UzakVeriKaynagi`
/// yazılıp (indir → önbelleğe yaz → [jsonCozumle]) uygulama durumuna verilebilir;
/// başarısız olursa asset'e geri düşülür.
abstract class VeriKaynagi {
  const VeriKaynagi();

  /// Kısa açıklama (Ayarlar ekranında gösterilir).
  String get aciklama;

  Future<VeriPaketi> yukle();

  /// Ham JSON metnini ayrı bir isolate'te çözer (ana iş parçacığını kilitlemez).
  static Future<VeriPaketi> jsonCozumle(String jsonMetni) =>
      compute(_coz, jsonMetni, debugLabel: 'kampanya-json');
}

VeriPaketi _coz(String metin) =>
    VeriPaketi.fromJson(jsonDecode(metin) as Map<String, dynamic>);

class AssetVeriKaynagi extends VeriKaynagi {
  final String yol;
  const AssetVeriKaynagi({this.yol = 'assets/kampanyalar.json'});

  @override
  String get aciklama => 'Uygulama içi veri';

  @override
  Future<VeriPaketi> yukle() async {
    final metin = await rootBundle.loadString(yol, cache: false);
    return VeriKaynagi.jsonCozumle(metin);
  }
}

/// Önce cihazdaki son indirilen veri (yoksa ya da APK'daki daha yeniyse asset);
/// [guncelle] sunucudan yenisini indirip önbelleğe yazar.
class SunucuVeriKaynagi extends VeriKaynagi {
  final AssetVeriKaynagi yedek;
  const SunucuVeriKaynagi({this.yedek = const AssetVeriKaynagi()});

  static String _aciklama = 'Uygulama içi veri';

  @override
  String get aciklama => _aciklama;

  static Future<File> _dosya() async => File('${(await getApplicationSupportDirectory()).path}/kampanyalar.json');

  static String _olusturma(String metin) =>
      RegExp(r'"uretim"\s*:\s*"([^"]+)"').firstMatch(metin.substring(0, min(400, metin.length)))?.group(1) ?? '';

  @override
  Future<VeriPaketi> yukle() async {
    final asset = await rootBundle.loadString(yedek.yol, cache: false);
    try {
      final f = await _dosya();
      if (await f.exists()) {
        final onbellek = await f.readAsString();
        if (_olusturma(onbellek).compareTo(_olusturma(asset)) > 0) {
          final p = await VeriKaynagi.jsonCozumle(onbellek);
          _aciklama = 'Sunucu';
          return p;
        }
      }
    } catch (e) {
      debugPrint('Önbellek okunamadı: $e');
    }
    _aciklama = 'Uygulama içi veri';
    return VeriKaynagi.jsonCozumle(asset);
  }

  /// Yeni veri varsa çözülmüş paketi döndürür; yoksa / hata olursa null.
  Future<VeriPaketi?> guncelle() async {
    final t = await SharedPreferences.getInstance();
    final r = await Sunucu.kampanyalar(t.getString('veri_etag'));
    if (r == null) return null;
    try {
      final p = await VeriKaynagi.jsonCozumle(r.metin);
      if (p.kampanyalar.isEmpty) return null;
      final f = await _dosya();
      await f.parent.create(recursive: true);
      await f.writeAsString(r.metin, flush: true);
      if (r.etag != null) await t.setString('veri_etag', r.etag!);
      _aciklama = 'Sunucu';
      return p;
    } catch (e) {
      Sunucu.olay('hata', 'kampanya_coz', e);
      return null;
    }
  }
}
