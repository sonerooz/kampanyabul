import 'dart:async';

import 'package:flutter/material.dart';

import '../durum.dart';
import '../ortak.dart';
import '../tema.dart';
import '../veri/katalog.dart';
import '../veri/model.dart';
import 'kampanya_karti.dart';

/// Ana sayfa: selamlama + arama, öne çıkanlar, kategoriler, kartlarına özel, son fırsatlar, bento.
class KesfetEkrani extends StatelessWidget {
  final void Function({String? grup, bool arama}) kampanyalaraGit;
  final VoidCallback kartlarimaGit;
  final VoidCallback profileGit;
  const KesfetEkrani({super.key, required this.kampanyalaraGit, required this.kartlarimaGit, required this.profileGit});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final p = d.paket!;
    final bugun = DateTime.now();
    final acik = p.kampanyalar.where((k) {
      final g = k.kalanGun(bugun);
      return g == null || g >= 0;
    }).toList();
    int bitis(Kampanya a, Kampanya b) => (a.bitis ?? DateTime(2100)).compareTo(b.bitis ?? DateTime(2100));

    final kartlarima = acik.where(d.kartlarimaUyar).toList()..sort(bitis);
    final sonGun = acik.where((k) => (k.kalanGun(bugun) ?? 99) <= 3 && k.odul != null).toList()..sort(bitis);
    final smsli = acik.where((k) => k.sms != null).toList()..sort(bitis);

    // Öne çıkanlar: her gruptan bir tane (görseller çeşitlensin), önce kartlarına uyanlar
    final havuz = [...kartlarima, ...acik.where((k) => k.odul != null && (k.kalanGun(bugun) ?? 99) <= 30).toList()..sort(bitis)];
    final oneCikan = <Kampanya>[];
    final gorulen = <String>{};
    for (final k in havuz) {
      if (k.grup == 'Diğer' || !gorulen.add(k.grup)) continue;
      oneCikan.add(k);
      if (oneCikan.length == 6) break;
    }

    final sayilar = <String, int>{};
    for (final k in acik) {
      sayilar[k.grup] = (sayilar[k.grup] ?? 0) + 1;
    }
    final gruplar = p.gruplar.where((g) => (sayilar[g] ?? 0) > 0).toList();
    final bento = (gruplar.where((g) => g != 'Diğer').toList()..sort((a, b) => sayilar[b]!.compareTo(sayilar[a]!))).take(3).toList();
    final alt = MediaQuery.paddingOf(context).bottom + 110;

    Widget ray(List<Kampanya> l) => SizedBox(
          height: 300,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: l.length.clamp(0, 12),
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (_, i) => KampanyaVitrini(kampanya: l[i], banka: p.bankalar[l[i].banka]!, bugun: bugun, genislik: 210),
          ),
        );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _Baslik(
              kampanyaSayisi: acik.length,
              aramaya: () => kampanyalaraGit(arama: true),
              profileGit: profileGit,
            ),
          ),
          if (oneCikan.isNotEmpty) SliverToBoxAdapter(child: _OneCikanlar(kampanyalar: oneCikan, bugun: bugun)),
          SliverToBoxAdapter(child: BolumBasligi('Kategoriler', tumu: () => kampanyalaraGit())),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: gruplar.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (_, i) => _KategoriYuvarlak(
                  grup: gruplar[i],
                  sayi: sayilar[gruplar[i]]!,
                  onTap: () => kampanyalaraGit(grup: gruplar[i]),
                ),
              ),
            ),
          ),
          if (kartlarima.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: BolumBasligi('Kartlarına özel', alt: '${kartlarima.length} kampanya cüzdanındaki kartlara uyuyor', tumu: () {
                d.sadeceKartlarim = true;
                kampanyalaraGit();
              }),
            ),
            SliverToBoxAdapter(child: ray(kartlarima)),
          ] else
            SliverToBoxAdapter(child: _KartEkleDavet(onTap: kartlarimaGit)),
          if (sonGun.isNotEmpty) ...[
            const SliverToBoxAdapter(child: BolumBasligi('Kaçırma, bitiyor', alt: 'Son 3 gün')),
            SliverToBoxAdapter(child: ray(sonGun)),
          ],
          if (bento.length == 3) ...[
            const SliverToBoxAdapter(child: BolumBasligi('En çok fırsat')),
            SliverToBoxAdapter(child: _Bento(gruplar: bento, sayilar: sayilar, sec: (g) => kampanyalaraGit(grup: g))),
          ],
          if (smsli.isNotEmpty) ...[
            SliverToBoxAdapter(child: BolumBasligi('SMS ile hemen katıl', alt: '${smsli.length} kampanyada tek mesaj yeterli')),
            SliverToBoxAdapter(child: ray(smsli)),
          ],
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 28, 16, alt),
              child: FilledButton.icon(
                onPressed: () => kampanyalaraGit(),
                icon: const Icon(Icons.local_offer_rounded),
                label: Text('Tüm kampanyaları gör (${acik.length})'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Baslik extends StatelessWidget {
  final int kampanyaSayisi;
  final VoidCallback aramaya;
  final VoidCallback profileGit;
  const _Baslik({required this.kampanyaSayisi, required this.aramaya, required this.profileGit});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final t = Theme.of(context).textTheme;
    final pr = d.profil;
    final saat = DateTime.now().hour;
    final selam = saat < 6 ? 'İyi geceler' : saat < 12 ? 'Günaydın' : saat < 18 ? 'İyi günler' : 'İyi akşamlar';
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(center: Alignment(-0.8, -1), radius: 1.4, colors: [Color(0xFF1F3B5A), R.zemin]),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pr == null ? '$selam 👋' : '$selam, ${pr.ad.split(' ').first} 👋',
                            style: t.titleMedium?.copyWith(color: R.soluk, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Bugün $kampanyaSayisi fırsat var',
                            style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: profileGit,
                    child: ProfilResmi(foto: pr?.foto, bas: pr?.bas ?? 'K', boyut: 50),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Material(
                color: Colors.white.withValues(alpha: 0.07),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: aramaya,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    child: Row(
                      children: [
                        Icon(Icons.search_rounded, color: R.soluk),
                        SizedBox(width: 12),
                        Expanded(child: Text('Mağaza, marka ya da kategori ara', style: TextStyle(color: R.soluk))),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Otomatik kayan büyük vitrin (5 sn); altta hap şeklinde sayfa göstergesi.
class _OneCikanlar extends StatefulWidget {
  final List<Kampanya> kampanyalar;
  final DateTime bugun;
  const _OneCikanlar({required this.kampanyalar, required this.bugun});

  @override
  State<_OneCikanlar> createState() => _OneCikanlarState();
}

class _OneCikanlarState extends State<_OneCikanlar> {
  final _pc = PageController(viewportFraction: 0.9);
  int _i = 0;
  Timer? _zaman;

  @override
  void initState() {
    super.initState();
    _zaman = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_pc.hasClients || widget.kampanyalar.length < 2) return;
      _pc.animateToPage((_i + 1) % widget.kampanyalar.length, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
    });
  }

  @override
  void dispose() {
    _zaman?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final t = Theme.of(context).textTheme;
    final l = widget.kampanyalar;
    return Column(
      children: [
        const SizedBox(height: 14),
        SizedBox(
          height: 360,
          child: PageView.builder(
            controller: _pc,
            itemCount: l.length,
            onPageChanged: (i) => setState(() => _i = i),
            itemBuilder: (_, i) {
              final k = l[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => detayaGit(context, k),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        KampanyaGorseli(dosya: k.gorsel, grup: k.grup, hiza: const Alignment(0.3, 0.2)),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Color(0x330F1626), Colors.transparent, Color(0xF00F1626)],
                              stops: [0, 0.35, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          top: 16,
                          child: Row(children: [
                            BankaRozeti(d.paket!.bankalar[k.banka]!, buyuk: true),
                            const SizedBox(width: 8),
                            KalanHapi(k.kalanGun(widget.bugun), koyu: true),
                          ]),
                        ),
                        Positioned(
                          left: 20,
                          right: 20,
                          bottom: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (k.odul != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: R.amber, borderRadius: BorderRadius.circular(100)),
                                  child: Text(k.odul!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(color: R.zemin, fontWeight: FontWeight.w800, fontSize: 13)),
                                ),
                              Text(k.baslik,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.3)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < l.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _i ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _i ? R.zumrut : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _KategoriYuvarlak extends StatelessWidget {
  final String grup;
  final int sayi;
  final VoidCallback onTap;
  const _KategoriYuvarlak({required this.grup, required this.sayi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [R.zumrut.withValues(alpha: 0.7), R.amber.withValues(alpha: 0.5)]),
              ),
              child: ClipOval(child: GrupGorseli(grup)),
            ),
            const SizedBox(height: 6),
            Text(grup.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$sayi', style: const TextStyle(fontSize: 11, color: R.soluk)),
          ],
        ),
      ),
    );
  }
}

class _KartEkleDavet extends StatelessWidget {
  final VoidCallback onTap;
  const _KartEkleDavet({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(colors: [Color(0xFF14806A), Color(0xFF1F3B5A)]),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Kartını ekle', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 4),
                      Text('Hangi kampanyanın sana uyduğunu biz bulalım. Kart numarası istemiyoruz.',
                          style: t.bodyMedium?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.add_card_rounded, color: R.zemin),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Üç kutulu ızgara: solda uzun, sağda üst üste iki kısa kutu.
class _Bento extends StatelessWidget {
  final List<String> gruplar;
  final Map<String, int> sayilar;
  final void Function(String) sec;
  const _Bento({required this.gruplar, required this.sayilar, required this.sec});

  Widget _kutu(BuildContext context, String g, {required double yukseklik}) => GestureDetector(
        onTap: () => sec(g),
        child: SizedBox(
          height: yukseklik,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              fit: StackFit.expand,
              children: [
                GrupGorseli(g),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xE60F1626)],
                      stops: [0.45, 1],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(g, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                      Text('${sayilar[g]} kampanya', style: const TextStyle(color: R.zumrut, fontSize: 12, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _kutu(context, gruplar[0], yukseklik: 300)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                children: [
                  _kutu(context, gruplar[1], yukseklik: 144),
                  const SizedBox(height: 12),
                  _kutu(context, gruplar[2], yukseklik: 144),
                ],
              ),
            ),
          ],
        ),
      );
}
