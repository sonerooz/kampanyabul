import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'hesap.dart';
import 'sunucu.dart';
import 'veri/cuzdan.dart';
import 'veri/katalog.dart';
import 'veri/model.dart';
import 'veri/normalize.dart';
import 'veri/veri_kaynagi.dart';

enum Siralama {
  bitisYakin('Bitişi yakın'),
  yeniEklenen('Yeni eklenen'),
  banka('Banka');

  final String etiket;
  const Siralama(this.etiket);
}

/// Uygulamanın tek durum nesnesi: veri, kartlarım seçimi ve ana ekran filtreleri.
class UygulamaDurumu extends ChangeNotifier {
  UygulamaDurumu(this.kaynak);

  static const _kKartlar = 'kartlarim';
  static const _kSadeceKartlarim = 'sadece_kartlarim';
  static const _kSiralama = 'siralama';
  static const _kCuzdan = 'cuzdan';
  static const _kFavori = 'favoriler';
  static const _kProfil = 'profil';
  static const _kGirisGoruldu = 'giris_goruldu';
  static const _kGorunum = 'izgara';

  final VeriKaynagi kaynak;
  SharedPreferences? _tercih;

  VeriPaketi? paket;

  /// Bankaların gerçek kart ürünleri (görsel / renk); yüklenene kadar null.
  KartKatalogu? katalog;

  /// Sunucudaki sabit görseller {dosya: içerik özeti} (kategori görselleri sunucudan değiştirilebilsin diye).
  Map<String, String> sabit = const {};
  Object? hata;
  bool get yuklendi => paket != null;

  // --- Hesap (cihazda)
  Profil? _profil;
  Profil? get profil => _profil;
  bool _girisGoruldu = true;
  bool get girisGoruldu => _girisGoruldu;

  // --- Favoriler (kampanya id)
  final Set<String> _favoriler = {};
  Set<String> get favoriler => Set.unmodifiable(_favoriler);
  bool favoriMi(String id) => _favoriler.contains(id);

  // --- Görünüm: ızgara (büyük görselli) / liste
  bool _izgara = false;
  bool get izgara => _izgara;

  // --- Cüzdan: kişinin eklediği kartlar; [kartlar] bunlardan türetilir
  final List<KisiKarti> _cuzdan = [];
  List<KisiKarti> get cuzdan => List.unmodifiable(_cuzdan);

  // --- Kartlarım (kalıcı)
  final Set<String> _kartlar = {};
  Set<String> get kartlar => Set.unmodifiable(_kartlar);
  bool _sadeceKartlarim = false;
  bool get sadeceKartlarim => _sadeceKartlarim;

  // --- Filtreler
  String _sorgu = '';
  List<String> _sorguKelimeleri = const [];
  String get sorgu => _sorgu;
  String? _grup; // null = Tümü
  String? get grup => _grup;
  final Set<String> _bankaFiltresi = {};
  Set<String> get bankaFiltresi => Set.unmodifiable(_bankaFiltresi);
  Siralama _siralama = Siralama.bitisYakin;
  Siralama get siralama => _siralama;

  // --- Hesaplanan sonuçlar
  List<Kampanya> _sonuc = const [];
  List<Kampanya> get sonuc => _sonuc;
  Map<String, int> _grupSayilari = const {};
  Map<String, int> get grupSayilari => _grupSayilari;
  int _grupsuzToplam = 0;
  int get grupsuzToplam => _grupsuzToplam;

  Future<void> baslat() async {
    try {
      _tercih = await SharedPreferences.getInstance();
      final t = _tercih!;
      final cz = t.getString(_kCuzdan);
      _cuzdan.clear();
      if (cz != null) {
        _cuzdan.addAll((jsonDecode(cz) as List).map((e) => KisiKarti.fromJson(e as Map<String, dynamic>)));
      } else {
        // eski sürümdeki işaretli kart programlarını cüzdana taşı
        var i = 0;
        for (final a in t.getStringList(_kKartlar) ?? const <String>[]) {
          final p = a.split('|');
          if (p.length == 2) _cuzdan.add(KisiKarti(id: 'eski${i++}', banka: p[0], program: p[1], stil: i % 4));
        }
      }
      _kartlariTuret();
      _favoriler
        ..clear()
        ..addAll(t.getStringList(_kFavori) ?? const []);
      final pr = t.getString(_kProfil);
      _profil = pr == null ? null : Profil.fromJson(jsonDecode(pr) as Map<String, dynamic>);
      _girisGoruldu = t.getBool(_kGirisGoruldu) ?? false;
      _izgara = t.getBool(_kGorunum) ?? false;
      _sadeceKartlarim = _tercih!.getBool(_kSadeceKartlarim) ?? false;
      final s = _tercih!.getString(_kSiralama);
      _siralama = Siralama.values.firstWhere((e) => e.name == s, orElse: () => Siralama.bitisYakin);
    } catch (e) {
      debugPrint('Tercihler okunamadı: $e');
    }
    unawaited(_katalogYukle());
    unawaited(_sabitYukle());
    await yenidenYukle();
  }

  Future<void> _sabitYukle() async {
    try {
      final eski = _tercih?.getString('sabit');
      if (eski != null) {
        sabit = Map<String, String>.from(jsonDecode(eski) as Map);
        notifyListeners();
      }
      final r = await Sunucu.indir('/api/sabit', null);
      if (r == null) return;
      final d = (jsonDecode(utf8.decode(r.veri)) as Map)['dosyalar'];
      if (d is Map) {
        sabit = Map<String, String>.from(d);
        await _tercih?.setString('sabit', jsonEncode(sabit));
        notifyListeners();
      }
    } catch (e) {
      Sunucu.olay('hata', 'sabit_yukle', e);
    }
  }

  Future<void> _katalogYukle() async {
    try {
      katalog = await KartKatalogu.yukle();
      notifyListeners();
      final yeni = await KartKatalogu.guncelle();
      if (yeni != null) {
        katalog = yeni;
        notifyListeners();
      }
    } catch (e) {
      Sunucu.olay('hata', 'katalog_yukle', e);
    }
  }

  Future<void> yenidenYukle() async {
    hata = null;
    notifyListeners();
    try {
      paket = await kaynak.yukle();
      _hesapla();
    } catch (e, st) {
      debugPrint('Veri yüklenemedi: $e\n$st');
      Sunucu.olay('hata', 'veri_yukle', '$e');
      hata = e;
    }
    notifyListeners();
    unawaited(sunucudanGuncelle());
  }

  bool _guncelleniyor = false;

  /// Arka planda sunucudan yeni kampanya verisi çeker; varsa ekranı tazeler.
  Future<bool> sunucudanGuncelle() async {
    final k = kaynak;
    if (k is! SunucuVeriKaynagi || _guncelleniyor) return false;
    _guncelleniyor = true;
    try {
      final p = await k.guncelle();
      if (p == null) return false;
      paket = p;
      _hesapla();
      notifyListeners();
      return true;
    } finally {
      _guncelleniyor = false;
    }
  }

  // ------------------------------------------------------------ kartlarım
  void _kartlariTuret() {
    _kartlar
      ..clear()
      ..addAll(_cuzdan.map((k) => k.anahtar));
  }

  void kartEkle(KisiKarti k, {int? sira}) {
    if (sira != null && sira >= 0 && sira <= _cuzdan.length) {
      _cuzdan.insert(sira, k);
    } else {
      _cuzdan.add(k);
    }
    _cuzdaniKaydet();
  }

  void kartGuncelle(KisiKarti k) {
    final i = _cuzdan.indexWhere((e) => e.id == k.id);
    if (i >= 0) _cuzdan[i] = k;
    _cuzdaniKaydet();
  }

  void kartSil(String id) {
    _cuzdan.removeWhere((e) => e.id == id);
    _cuzdaniKaydet();
  }

  void _cuzdaniKaydet() {
    _kartlariTuret();
    _tercih?.setString(_kCuzdan, jsonEncode(_cuzdan.map((e) => e.toJson()).toList()));
    _tercih?.setStringList(_kKartlar, _kartlar.toList()..sort());
    _hesaplaVeBildir();
  }

  /// Bir cüzdan kartına uyan (bitmemiş) kampanyalar, bitişi yakın olan önce.
  List<Kampanya> kartKampanyalari(KisiKarti k) {
    final bugun = DateTime.now();
    final l = paket!.kampanyalar.where((c) {
      if (c.banka != k.banka || !c.programlar.contains(k.program)) return false;
      final g = c.kalanGun(bugun);
      return g == null || g >= 0;
    }).toList();
    l.sort((a, b) => (a.bitis ?? DateTime(2100)).compareTo(b.bitis ?? DateTime(2100)));
    return l;
  }

  // ------------------------------------------------------------ favoriler
  void favoriDegistir(String id) {
    _favoriler.contains(id) ? _favoriler.remove(id) : _favoriler.add(id);
    _tercih?.setStringList(_kFavori, _favoriler.toList());
    notifyListeners();
  }

  List<Kampanya> get favoriKampanyalar =>
      paket == null ? const [] : paket!.kampanyalar.where((k) => _favoriler.contains(k.id)).toList();

  set izgara(bool v) {
    _izgara = v;
    _tercih?.setBool(_kGorunum, v);
    notifyListeners();
  }

  // ------------------------------------------------------------ hesap
  void girisYapildi(Profil p) {
    _profil = p;
    _tercih?.setString(_kProfil, jsonEncode(p.toJson()));
    girisGoruldu = true;
  }

  Future<void> cikisYap() async {
    final p = _profil;
    _profil = null;
    _tercih?.remove(_kProfil);
    notifyListeners();
    if (p != null) await SosyalGiris.cikis(p.saglayici);
  }

  set girisGoruldu(bool v) {
    _girisGoruldu = v;
    _tercih?.setBool(_kGirisGoruldu, v);
    notifyListeners();
  }

  set sadeceKartlarim(bool v) {
    _sadeceKartlarim = v;
    _tercih?.setBool(_kSadeceKartlarim, v);
    _hesaplaVeBildir();
  }

  bool kartlarimaUyar(Kampanya k) {
    for (final p in k.programlar) {
      if (_kartlar.contains(kartAnahtari(k.banka, p))) return true;
    }
    return false;
  }

  // ------------------------------------------------------------ filtreler
  set sorgu(String v) {
    if (v == _sorgu) return;
    _sorgu = v;
    _sorguKelimeleri = sorguKelimeleri(v);
    _hesaplaVeBildir();
  }

  set grup(String? g) {
    _grup = g;
    _hesaplaVeBildir();
  }

  void bankaFiltresiAyarla(Set<String> bankalar) {
    _bankaFiltresi
      ..clear()
      ..addAll(bankalar);
    _hesaplaVeBildir();
  }

  set siralama(Siralama s) {
    _siralama = s;
    _tercih?.setString(_kSiralama, s.name);
    _hesaplaVeBildir();
  }

  void _hesaplaVeBildir() {
    _hesapla();
    notifyListeners();
  }

  /// Grup dışındaki tüm filtreler uygulanır → grup sayıları; sonra grup filtresi → liste.
  void _hesapla() {
    final p = paket;
    if (p == null) return;
    final kartFiltresi = _sadeceKartlarim;
    final bugun = DateTime.now();
    final temel = <Kampanya>[];
    for (final k in p.kampanyalar) {
      // Veri gömülü olduğu için yayından sonra bitenleri çalışma anında gizle
      final kalan = k.kalanGun(bugun);
      if (kalan != null && kalan < 0) continue;
      if (_bankaFiltresi.isNotEmpty && !_bankaFiltresi.contains(k.banka)) continue;
      if (kartFiltresi && !kartlarimaUyar(k)) continue;
      if (_sorguKelimeleri.isNotEmpty && !k.eslesir(_sorguKelimeleri)) continue;
      temel.add(k);
    }
    final sayilar = <String, int>{};
    for (final k in temel) {
      sayilar[k.grup] = (sayilar[k.grup] ?? 0) + 1;
    }
    _grupSayilari = sayilar;
    _grupsuzToplam = temel.length;
    final g = _grup;
    final liste = g == null ? temel : temel.where((k) => k.grup == g).toList();
    liste.sort(_karsilastirici(p));
    _sonuc = liste;
  }

  Comparator<Kampanya> _karsilastirici(VeriPaketi p) {
    int bitis(Kampanya a, Kampanya b) {
      final x = a.bitis, y = b.bitis;
      if (x == null && y == null) return 0;
      if (x == null) return 1;
      if (y == null) return -1;
      return x.compareTo(y);
    }

    switch (_siralama) {
      case Siralama.bitisYakin:
        return (a, b) {
          final c = bitis(a, b);
          return c != 0 ? c : a.sira.compareTo(b.sira);
        };
      case Siralama.yeniEklenen:
        return (a, b) {
          final x = a.baslangic, y = b.baslangic;
          if (x != null || y != null) {
            if (x == null) return 1;
            if (y == null) return -1;
            final c = y.compareTo(x);
            if (c != 0) return c;
          }
          return bitis(a, b);
        };
      case Siralama.banka:
        final ad = {for (final e in p.bankalar.entries) e.key: norm(e.value.ad)};
        return (a, b) {
          final c = ad[a.banka]!.compareTo(ad[b.banka]!);
          if (c != 0) return c;
          final d = bitis(a, b);
          return d != 0 ? d : a.sira.compareTo(b.sira);
        };
    }
  }
}

/// Durumu ağaca yayar; `UygulamaKapsami.of(context)` dinleyerek erişir.
class UygulamaKapsami extends InheritedNotifier<UygulamaDurumu> {
  const UygulamaKapsami({super.key, required UygulamaDurumu durum, required super.child})
      : super(notifier: durum);

  static UygulamaDurumu of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UygulamaKapsami>()!.notifier!;

  /// Dinlemeden erişim (olay işleyicilerinde).
  static UygulamaDurumu oku(BuildContext context) =>
      context.getInheritedWidgetOfExactType<UygulamaKapsami>()!.notifier!;
}
