import 'model.dart';

/// Kişinin cüzdanına eklediği kart. Kart numarası tutulmaz; yalnız isteğe bağlı son 4 hane (cihazda).
class KisiKarti {
  final String id;
  final String banka; // Banka.anahtar
  final String program; // ör. "Axess"
  final String? takmaAd; // ör. "Maaş kartım"
  final String? son4;
  final int stil; // eski sürümden kalan; artık kullanıcı seçmez (kart görünümü katalogdan gelir)
  final String? kartId; // KatalogKarti.id — bankanın gerçek kart ürünü
  final String? kartAdi; // ör. "Bonus Platinum" (katalog yoksa da gösterilsin diye saklanır)

  const KisiKarti({
    required this.id,
    required this.banka,
    required this.program,
    this.takmaAd,
    this.son4,
    this.stil = 0,
    this.kartId,
    this.kartAdi,
  });

  String get anahtar => kartAnahtari(banka, program);

  KisiKarti kopya({String? takmaAd, String? son4}) => KisiKarti(
        id: id,
        banka: banka,
        program: program,
        takmaAd: takmaAd ?? this.takmaAd,
        son4: son4 ?? this.son4,
        stil: stil,
        kartId: kartId,
        kartAdi: kartAdi,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'b': banka,
        'p': program,
        if (takmaAd != null) 'ad': takmaAd,
        if (son4 != null) 's4': son4,
        'st': stil,
        if (kartId != null) 'k': kartId,
        if (kartAdi != null) 'ka': kartAdi,
      };

  factory KisiKarti.fromJson(Map<String, dynamic> j) => KisiKarti(
        id: j['id'] as String,
        banka: j['b'] as String,
        program: j['p'] as String,
        takmaAd: j['ad'] as String?,
        son4: j['s4'] as String?,
        stil: (j['st'] as num?)?.toInt() ?? 0,
        kartId: j['k'] as String?,
        kartAdi: j['ka'] as String?,
      );
}
