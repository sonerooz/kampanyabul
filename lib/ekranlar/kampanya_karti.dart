import 'package:flutter/material.dart';

import '../durum.dart';
import '../ortak.dart';
import '../tema.dart';
import '../veri/katalog.dart';
import '../veri/model.dart';
import 'detay_ekrani.dart';

void detayaGit(BuildContext context, Kampanya k) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => DetayEkrani(kampanya: k)));

/// Kalan süre hapı: 3 günden az → mercan.
class KalanHapi extends StatelessWidget {
  final int? kalan;
  final bool koyu;
  const KalanHapi(this.kalan, {super.key, this.koyu = false});

  @override
  Widget build(BuildContext context) {
    final m = kalanEtiket(kalan);
    if (m == null) return const SizedBox.shrink();
    final acil = kalan != null && kalan! < 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: acil ? R.mercan : (koyu ? Colors.black.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.08)),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(acil ? Icons.local_fire_department_rounded : Icons.schedule_rounded, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(m, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
        ],
      ),
    );
  }
}

/// Favori (yer imi) düğmesi.
class FavoriDugmesi extends StatelessWidget {
  final String id;
  final double boyut;
  const FavoriDugmesi(this.id, {super.key, this.boyut = 22});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final f = d.favoriMi(id);
    return IconButton(
      visualDensity: VisualDensity.compact,
      tooltip: f ? 'Favorilerden çıkar' : 'Favorilere ekle',
      onPressed: () {
        d.favoriDegistir(id);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
            content: Text(f ? 'Favorilerden çıkarıldı' : 'Favorilere eklendi'),
            duration: const Duration(milliseconds: 1200),
          ));
      },
      icon: Icon(f ? Icons.bookmark_rounded : Icons.bookmark_border_rounded, size: boyut, color: f ? R.amber : R.yazi),
    );
  }
}

/// Liste satırı: solda grup görseli, sağda banka, başlık, ödül ve kalan süre.
class KampanyaSatiri extends StatelessWidget {
  final Kampanya kampanya;
  final Banka banka;
  final DateTime bugun;
  const KampanyaSatiri({super.key, required this.kampanya, required this.banka, required this.bugun});

  @override
  Widget build(BuildContext context) {
    final k = kampanya;
    final t = Theme.of(context).textTheme;
    final kartimda = UygulamaKapsami.of(context).kartlarimaUyar(k);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => detayaGit(context, k),
          child: Ink(
            decoration: camKutu(vurgulu: kartimda),
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: KampanyaGorseli(dosya: k.gorsel, grup: k.grup, genislik: 86, yukseklik: 104),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          BankaRozeti(banka),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              k.programlar.join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.labelSmall?.copyWith(color: R.soluk),
                            ),
                          ),
                          if (kartimda) const Icon(Icons.verified_rounded, size: 16, color: R.zumrut),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        k.baslik,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              k.odul ?? k.grup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: t.labelLarge?.copyWith(
                                color: k.odul != null ? R.amber : R.soluk,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          KalanHapi(k.kalanGun(bugun)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Vitrin kartı: üstte büyük görsel (degrade örtülü), altta başlık ve ödül.
class KampanyaVitrini extends StatelessWidget {
  final Kampanya kampanya;
  final Banka banka;
  final DateTime bugun;
  final double? genislik;
  const KampanyaVitrini({super.key, required this.kampanya, required this.banka, required this.bugun, this.genislik});

  @override
  Widget build(BuildContext context) {
    final k = kampanya;
    final t = Theme.of(context).textTheme;
    final kart = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => detayaGit(context, k),
        child: Ink(
          decoration: camKutu(yaricap: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.25,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                      child: KampanyaGorseli(dosya: k.gorsel, grup: k.grup, hiza: const Alignment(0, 0.25)),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC19243D)],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                    Positioned(left: 10, top: 10, child: KalanHapi(k.kalanGun(bugun), koyu: true)),
                    Positioned(right: 2, top: 2, child: FavoriDugmesi(k.id)),
                    Positioned(left: 10, bottom: 8, child: BankaRozeti(banka)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.baslik,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.25),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      k.odul ?? k.programlar.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.labelLarge?.copyWith(color: k.odul != null ? R.amber : R.soluk, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    return genislik == null ? kart : SizedBox(width: genislik, child: kart);
  }
}
