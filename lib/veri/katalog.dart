import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../durum.dart';
import '../ortak.dart';
import '../sunucu.dart';

/// Bankanın sitesindeki gerçek kart ürünü (sunucudaki haftalık kart kataloğundan).
class KatalogKarti {
  final String id;
  final String banka;
  final String ad;
  final String? program;
  final String? tur; // kredi | banka | sanal | ticari | on_odemeli
  final String? gorsel; // düz kart önyüzü varsa "<id>.webp"
  final List<Color> renk; // görselden çıkarılmış baskın iki renk (koyu → açık)

  const KatalogKarti({
    required this.id,
    required this.banka,
    required this.ad,
    this.program,
    this.tur,
    this.gorsel,
    this.renk = const [],
  });

  static Color? _renk(Object? s) {
    if (s is! String || s.length != 7) return null;
    final v = int.tryParse(s.substring(1), radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }

  factory KatalogKarti.fromJson(String banka, Map<String, dynamic> j) => KatalogKarti(
        id: j['id'] as String,
        banka: banka,
        ad: j['ad'] as String,
        program: j['program'] as String?,
        tur: j['tur'] as String?,
        gorsel: j['gorsel'] as String?,
        renk: [for (final r in (j['renk'] as List? ?? const [])) ?_renk(r)],
      );
}

class KartKatalogu {
  final Map<String, List<KatalogKarti>> bankalar;
  final Map<String, KatalogKarti> _id;

  KartKatalogu(this.bankalar) : _id = {for (final l in bankalar.values) for (final k in l) k.id: k};

  KatalogKarti? kart(String? id) => id == null ? null : _id[id];
  List<KatalogKarti> banka(String b) => bankalar[b] ?? const [];

  static KartKatalogu coz(String metin) {
    final j = jsonDecode(metin) as Map<String, dynamic>;
    return KartKatalogu({
      for (final e in (j['bankalar'] as Map<String, dynamic>).entries)
        e.key: [for (final k in e.value as List) KatalogKarti.fromJson(e.key, k as Map<String, dynamic>)],
    });
  }

  static Future<File> _dosya() async => File('${(await getApplicationSupportDirectory()).path}/kart_katalog.json');

  /// Önce cihazdaki son indirilen, yoksa APK'daki katalog.
  static Future<KartKatalogu> yukle() async {
    try {
      final f = await _dosya();
      if (await f.exists()) return coz(await f.readAsString());
    } catch (e) {
      debugPrint('Kart kataloğu önbelleği okunamadı: $e');
    }
    return coz(await rootBundle.loadString('assets/kart_katalog.json'));
  }

  /// Sunucudan yenisi varsa indirip önbelleğe yazar.
  static Future<KartKatalogu?> guncelle() async {
    final t = await SharedPreferences.getInstance();
    final r = await Sunucu.indir('/api/kart_katalog', t.getString('katalog_etag'));
    if (r == null) return null;
    try {
      final k = coz(utf8.decode(r.veri));
      if (k.bankalar.isEmpty) return null;
      final f = await _dosya();
      await f.parent.create(recursive: true);
      await f.writeAsBytes(r.veri, flush: true);
      if (r.etag != null) await t.setString('katalog_etag', r.etag!);
      return k;
    } catch (e) {
      Sunucu.olay('hata', 'katalog_coz', e);
      return null;
    }
  }
}

/// Sunucudaki görsel (kart / kampanya): cihazda önbellek, yoksa bir kez indirilir; inene kadar [yedek] gösterilir.
class SunucuGorseli extends StatefulWidget {
  final String yol; // ör. /kart/ab12.webp, /kgorsel/cd34.webp
  final Widget yedek;
  final Alignment hiza;
  const SunucuGorseli({super.key, required this.yol, required this.yedek, this.hiza = Alignment.center});

  static final _bekleyen = <String, Future<File?>>{};

  static Future<File?> getir(String yol) => _bekleyen[yol] ??= () async {
        final f = File('${(await getApplicationSupportDirectory()).path}/gorsel${yol.replaceAll(RegExp(r'[/?=&]'), '_')}');
        if (await f.exists() && await f.length() > 0) return f;
        final r = await Sunucu.indir(yol, null);
        if (r == null) {
          _bekleyen.remove(yol); // sonra yeniden dene
          return null;
        }
        await f.parent.create(recursive: true);
        await f.writeAsBytes(r.veri, flush: true);
        return f;
      }();

  @override
  State<SunucuGorseli> createState() => _SunucuGorseliState();
}

class _SunucuGorseliState extends State<SunucuGorseli> {
  File? _f;

  @override
  void initState() {
    super.initState();
    _yukle();
  }

  @override
  void didUpdateWidget(SunucuGorseli eski) {
    super.didUpdateWidget(eski);
    if (eski.yol != widget.yol) {
      _f = null;
      _yukle();
    }
  }

  Future<void> _yukle() async {
    final f = await SunucuGorseli.getir(widget.yol);
    if (mounted && f != null) setState(() => _f = f);
  }

  @override
  Widget build(BuildContext context) => _f == null
      ? widget.yedek
      : Image.file(_f!, fit: BoxFit.cover, alignment: widget.hiza, gaplessPlayback: true, errorBuilder: (_, _, _) => widget.yedek);
}

/// Kart kataloğu görseli.
class KartGorseli extends StatelessWidget {
  final String dosya;
  final Widget yedek;
  const KartGorseli({super.key, required this.dosya, required this.yedek});

  @override
  Widget build(BuildContext context) => SunucuGorseli(yol: '/kart/$dosya', yedek: yedek);
}

/// Kategori görseli: sunucudaki güncel hali (veri/sabit, /api/sabit özetiyle), yoksa uygulama içindeki.
class GrupGorseli extends StatelessWidget {
  final String grup;
  final Alignment hiza;
  final double? genislik, yukseklik;
  const GrupGorseli(this.grup, {super.key, this.hiza = Alignment.center, this.genislik, this.yukseklik});

  @override
  Widget build(BuildContext context) {
    final dosya = grupDosyasi(grup);
    final yedek = Image.asset('assets/gorsel/$dosya', width: genislik, height: yukseklik, fit: BoxFit.cover, alignment: hiza);
    final ozet = UygulamaKapsami.of(context).sabit[dosya];
    if (ozet == null) return yedek;
    return SizedBox(width: genislik, height: yukseklik, child: SunucuGorseli(yol: '/sabit/$dosya?v=$ozet', yedek: yedek, hiza: hiza));
  }
}

/// Kampanya görseli: kampanyaya özel görsel varsa o, yoksa kategori görseli.
class KampanyaGorseli extends StatelessWidget {
  final String? dosya;
  final String grup;
  final Alignment hiza;
  final double? genislik, yukseklik;
  const KampanyaGorseli({super.key, required this.dosya, required this.grup, this.hiza = Alignment.center, this.genislik, this.yukseklik});

  @override
  Widget build(BuildContext context) {
    final yedek = GrupGorseli(grup, hiza: hiza, genislik: genislik, yukseklik: yukseklik);
    if (dosya == null) return yedek;
    return SizedBox(width: genislik, height: yukseklik, child: SunucuGorseli(yol: '/kgorsel/$dosya', yedek: yedek));
  }
}
