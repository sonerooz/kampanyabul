import 'dart:ui' show Color;

/// Bir kart programına (banka + program) ait seçim anahtarı: "akbank|Axess".
String kartAnahtari(String banka, String program) => '$banka|$program';

class Banka {
  final String anahtar;
  final String ad;
  final String kisa;
  final Color renk;
  final Color yazi;

  const Banka({
    required this.anahtar,
    required this.ad,
    required this.kisa,
    required this.renk,
    required this.yazi,
  });

  static Color _renk(String? hex, Color varsayilan) {
    if (hex == null || !hex.startsWith('#') || hex.length != 7) return varsayilan;
    return Color(int.parse('FF${hex.substring(1)}', radix: 16));
  }

  factory Banka.fromJson(String anahtar, Map<String, dynamic> j) => Banka(
        anahtar: anahtar,
        ad: j['ad'] as String,
        kisa: (j['kisa'] as String?) ?? j['ad'] as String,
        renk: _renk(j['renk'] as String?, const Color(0xFF555555)),
        yazi: _renk(j['yazi'] as String?, const Color(0xFFFFFFFF)),
      );
}

class SmsKatilim {
  final String kod;
  final String numara;

  /// Kodun ardına boşlukla eklenmesi gereken bilgi (ör. "kartınızın son 6 hanesini").
  final String? ek;

  const SmsKatilim({required this.kod, required this.numara, this.ek});

  String get govde => ek == null ? kod : '$kod ';
}

class Kampanya {
  final String id;
  final String banka; // Banka.anahtar
  final List<String> programlar;
  final String baslik;
  final String grup;
  final String? kategori;
  final String? marka;
  final DateTime? baslangic;
  final DateTime? bitis;
  final int? minHarcama;
  final String? odul;
  final String? katilim;
  final bool katilimGerekli;
  final SmsKatilim? sms;
  final List<String> gecerliKartlar;
  final List<String> haricKartlar;
  final String? segment;
  final String? kaynakUrl;
  final String detay;

  /// Bankanın kampanya sayfasından alınmış kampanyaya özel görsel (sunucuda /kgorsel/<dosya>); yoksa kategori görseli.
  final String? gorsel;

  /// Başında boşluk olan arama metni: kelime başı eşleşmesi için " " + kelime aranır.
  final String ara;

  /// Asset/sunucudaki sıra (ilk yüklemedeki konum) — kararlı sıralama için.
  final int sira;

  const Kampanya({
    required this.id,
    required this.banka,
    required this.programlar,
    required this.baslik,
    required this.grup,
    this.kategori,
    this.marka,
    this.baslangic,
    this.bitis,
    this.minHarcama,
    this.odul,
    this.katilim,
    required this.katilimGerekli,
    this.sms,
    this.gecerliKartlar = const [],
    this.haricKartlar = const [],
    this.segment,
    this.kaynakUrl,
    required this.detay,
    this.gorsel,
    required this.ara,
    required this.sira,
  });

  static DateTime? _tarih(Object? v) {
    if (v is! String || v.length < 10) return null;
    return DateTime.tryParse(v.substring(0, 10));
  }

  static List<String> _liste(Object? v) =>
      v is List ? v.whereType<String>().toList(growable: false) : const [];

  factory Kampanya.fromJson(Map<String, dynamic> j, int sira) {
    final s = j['sms'];
    final min = j['min'];
    return Kampanya(
      id: j['id'] as String,
      banka: j['b'] as String,
      gorsel: j['gr'] as String?,
      programlar: _liste(j['kp']),
      baslik: j['t'] as String,
      grup: (j['g'] as String?) ?? 'Diğer',
      kategori: j['k'] as String?,
      marka: j['m'] as String?,
      baslangic: _tarih(j['bs']),
      bitis: _tarih(j['bt']),
      minHarcama: min is num ? min.round() : null,
      odul: j['o'] as String?,
      katilim: j['kat'] as String?,
      katilimGerekli: j['kg'] == true,
      sms: s is Map
          ? SmsKatilim(
              kod: s['kod'] as String,
              numara: s['no'] as String,
              ek: s['ek'] as String?,
            )
          : null,
      gecerliKartlar: _liste(j['gk']),
      haricKartlar: _liste(j['hk']),
      segment: j['seg'] as String?,
      kaynakUrl: j['url'] as String?,
      detay: (j['d'] as String?) ?? '',
      ara: ' ${(j['a'] as String?) ?? ''}',
      sira: sira,
    );
  }

  /// Bugüne göre kalan gün (bitiş günü dahil: bugün bitiyorsa 0).
  int? kalanGun(DateTime bugun) {
    final b = bitis;
    if (b == null) return null;
    final g = DateTime(bugun.year, bugun.month, bugun.day);
    return DateTime(b.year, b.month, b.day).difference(g).inDays;
  }

  /// Tüm sorgu kelimeleri arama metninde bir kelimenin başında geçiyor mu?
  bool eslesir(List<String> kelimeler) {
    for (final k in kelimeler) {
      if (!ara.contains(' $k')) return false;
    }
    return true;
  }
}

/// Tek seferde yüklenen veri paketi.
class VeriPaketi {
  final String? olusturma;
  final String? uretim;
  final List<String> gruplar;
  final Map<String, Banka> bankalar;
  final List<Kampanya> kampanyalar;

  const VeriPaketi({
    required this.olusturma,
    required this.uretim,
    required this.gruplar,
    required this.bankalar,
    required this.kampanyalar,
  });

  factory VeriPaketi.fromJson(Map<String, dynamic> j) {
    final bankalar = <String, Banka>{
      for (final e in (j['bankalar'] as Map<String, dynamic>).entries)
        e.key: Banka.fromJson(e.key, e.value as Map<String, dynamic>),
    };
    final ham = j['kampanyalar'] as List;
    final kampanyalar = <Kampanya>[
      for (var i = 0; i < ham.length; i++)
        Kampanya.fromJson(ham[i] as Map<String, dynamic>, i),
    ];
    // Bilinmeyen bankalı kayıt gelirse (ileride sunucudan) gri rozetle göster
    for (final k in kampanyalar) {
      bankalar.putIfAbsent(
        k.banka,
        () => Banka(
          anahtar: k.banka,
          ad: k.banka,
          kisa: k.banka,
          renk: const Color(0xFF666666),
          yazi: const Color(0xFFFFFFFF),
        ),
      );
    }
    return VeriPaketi(
      olusturma: j['olusturma'] as String?,
      uretim: j['uretim'] as String?,
      gruplar: (j['gruplar'] as List?)?.whereType<String>().toList() ?? const [],
      bankalar: bankalar,
      kampanyalar: kampanyalar,
    );
  }

  /// Banka → o bankadaki kart programları ve kampanya sayıları (veriden türetilir).
  Map<String, Map<String, int>> programSayilari() {
    final m = <String, Map<String, int>>{};
    for (final k in kampanyalar) {
      final p = m.putIfAbsent(k.banka, () => <String, int>{});
      for (final pr in k.programlar) {
        p[pr] = (p[pr] ?? 0) + 1;
      }
    }
    return m;
  }
}
