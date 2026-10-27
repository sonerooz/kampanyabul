import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../durum.dart';
import '../ortak.dart';
import '../tema.dart';
import '../veri/cuzdan.dart';
import '../veri/katalog.dart';
import '../veri/model.dart';
import '../veri/normalize.dart';
import 'kampanya_karti.dart';

/// Cüzdan: kişinin eklediği kartlar üst üste dizili; seçilen kartın kampanyaları altta.
/// Kart görünümü bankanın gerçek kartından gelir (katalog); sola kaydırınca silinir.
class KartlarimEkrani extends StatefulWidget {
  const KartlarimEkrani({super.key});

  @override
  State<KartlarimEkrani> createState() => _KartlarimEkraniState();
}

class _KartlarimEkraniState extends State<KartlarimEkrani> {
  String? _seciliId;

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final p = d.paket!;
    final t = Theme.of(context).textTheme;
    final cuzdan = d.cuzdan;
    final secili = cuzdan.where((k) => k.id == _seciliId).firstOrNull ?? cuzdan.lastOrNull;
    final kampanyalar = secili == null ? const <Kampanya>[] : d.kartKampanyalari(secili);
    final bugun = DateTime.now();
    final alt = MediaQuery.paddingOf(context).bottom + 100;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Kartlarım', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                          Text(
                            cuzdan.isEmpty ? 'Kartını ekle, sana uyan kampanyaları bulalım' : '${cuzdan.length} kart · ${d.kartlar.length} program',
                            style: t.bodySmall?.copyWith(color: R.soluk),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                      onPressed: () => _kartEkle(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Kart ekle'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (cuzdan.isEmpty)
            SliverFillRemaining(hasScrollBody: false, child: _BosCuzdan(ekle: () => _kartEkle(context)))
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  children: [
                    for (final k in cuzdan)
                      Align(
                        alignment: Alignment.topCenter,
                        // seçili ve son kart tam, diğerleri yalnız üst şeridi görünür (cüzdan yığını)
                        heightFactor: k.id == secili?.id || k == cuzdan.last ? 1 : 0.3,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: k.id == secili?.id && k != cuzdan.last ? 14 : 0),
                          child: Dismissible(
                            key: ValueKey('kart-${k.id}'),
                            direction: DismissDirection.endToStart,
                            background: const _SilZemini(),
                            onDismissed: (_) => _sil(context, k),
                            child: GestureDetector(
                              onTap: () => setState(() => _seciliId = k.id),
                              onLongPress: () => _kartMenusu(context, k),
                              child: CuzdanKarti(kart: k, banka: p.bankalar[k.banka]!, kampanyaSayisi: d.kartKampanyalari(k).length),
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.swipe_left_rounded, size: 16, color: R.soluk),
                        const SizedBox(width: 6),
                        Text('Silmek için kartı sola kaydır · düzenlemek için basılı tut', style: t.bodySmall?.copyWith(color: R.soluk)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (secili != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                  child: Text(
                    '${secili.takmaAd ?? secili.kartAdi ?? secili.program} için ${kampanyalar.length} kampanya',
                    style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            SliverPadding(
              padding: EdgeInsets.only(bottom: alt),
              sliver: SliverList.builder(
                itemCount: kampanyalar.length,
                itemBuilder: (_, i) => KampanyaSatiri(kampanya: kampanyalar[i], banka: p.bankalar[kampanyalar[i].banka]!, bugun: bugun),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _kartEkle(BuildContext context) async {
    final d = UygulamaKapsami.oku(context);
    final k = await showModalBottomSheet<KisiKarti>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => UygulamaKapsami(durum: d, child: const _KartEkleSayfasi()),
    );
    if (k != null) {
      d.kartEkle(k);
      setState(() => _seciliId = k.id);
    }
  }

  Future<void> _kartMenusu(BuildContext context, KisiKarti k) async {
    final secim = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: const Icon(Icons.edit_rounded), title: const Text('Takma adı / son 4 haneyi düzenle'), onTap: () => Navigator.pop(c, 'duzenle')),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: R.mercan),
              title: const Text('Kartı kaldır', style: TextStyle(color: R.mercan)),
              onTap: () => Navigator.pop(c, 'sil'),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (secim) {
      case 'sil':
        _sil(context, k);
      case 'duzenle':
        await _duzenle(context, k);
    }
  }

  Future<void> _duzenle(BuildContext context, KisiKarti k) async {
    final d = UygulamaKapsami.oku(context);
    final yeni = await showModalBottomSheet<KisiKarti>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => UygulamaKapsami(durum: d, child: _KartEkleSayfasi(duzenle: k)),
    );
    if (yeni != null) d.kartGuncelle(yeni);
  }

  /// Hemen siler; birkaç saniye "Geri al" sunar (aynı sıraya geri koyar).
  void _sil(BuildContext context, KisiKarti k) {
    final d = UygulamaKapsami.oku(context);
    final sira = d.cuzdan.indexWhere((e) => e.id == k.id);
    final ad = k.takmaAd ?? k.kartAdi ?? k.program;
    d.kartSil(k.id);
    if (_seciliId == k.id) setState(() => _seciliId = null);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('"$ad" silindi'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        action: SnackBarAction(label: 'Geri al', onPressed: () => d.kartEkle(k, sira: sira)),
      ));
  }
}

class _SilZemini extends StatelessWidget {
  const _SilZemini();

  @override
  Widget build(BuildContext context) => Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 28),
        decoration: BoxDecoration(color: R.mercan.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(22)),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white),
            SizedBox(width: 6),
            Text('Sil', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          ],
        ),
      );
}

/// Cüzdandaki kart: bankanın gerçek kart görseli; görsel yoksa kartın kendi renkleriyle çizilmiş kart.
class CuzdanKarti extends StatelessWidget {
  final KisiKarti kart;
  final Banka banka;
  final int kampanyaSayisi;
  const CuzdanKarti({super.key, required this.kart, required this.banka, required this.kampanyaSayisi});

  @override
  Widget build(BuildContext context) {
    final kat = UygulamaKapsami.of(context).katalog?.kart(kart.kartId);
    final cizim = _CizimKart(kart: kart, banka: banka, katalog: kat, kampanyaSayisi: kampanyaSayisi);
    return AspectRatio(
      aspectRatio: 1.586,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: kat?.gorsel == null
              ? cizim
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    KartGorseli(dosya: kat!.gorsel!, yedek: cizim),
                    // gerçek kartın üstünde yalnız küçük bilgi hapı
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 10,
                      child: Row(
                        children: [
                          if (kart.takmaAd != null || kart.son4 != null)
                            Flexible(child: _Hap([kart.takmaAd, if (kart.son4 != null) '•• ${kart.son4}'].whereType<String>().join('  '))),
                          const Spacer(),
                          _Hap('$kampanyaSayisi kampanya'),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _Hap extends StatelessWidget {
  final String yazi;
  const _Hap(this.yazi);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(100)),
        child: Text(yazi, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
      );
}

/// Görseli olmayan kartlar için çizim: renkler gerçek karttan (katalog), yoksa banka renginden.
class _CizimKart extends StatelessWidget {
  final KisiKarti kart;
  final Banka banka;
  final KatalogKarti? katalog;
  final int kampanyaSayisi;
  const _CizimKart({required this.kart, required this.banka, required this.katalog, required this.kampanyaSayisi});

  @override
  Widget build(BuildContext context) {
    final List<Color> renk;
    if (katalog != null && katalog!.renk.length == 2) {
      renk = katalog!.renk;
    } else {
      final hsl = HSLColor.fromColor(banka.renk);
      renk = [hsl.withLightness((hsl.lightness * 0.45).clamp(0.05, 0.4)).toColor(), banka.renk];
    }
    final orta = Color.lerp(renk[0], renk[1], 0.5)!;
    final yazi = orta.computeLuminance() > 0.5 ? const Color(0xFF14171F) : Colors.white;
    final ad = kart.kartAdi ?? katalog?.ad ?? kart.program;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [renk[1], renk[0]]),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Stack(
        children: [
          Positioned(right: -60, top: -40, child: _Halka(220, yazi)),
          Positioned(right: 40, bottom: -90, child: _Halka(180, yazi)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(banka.kisa, style: TextStyle(color: yazi, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    const Spacer(),
                    Flexible(
                      child: Text(ad, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: yazi, fontWeight: FontWeight.w700, fontSize: 13)),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: 40,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    gradient: const LinearGradient(colors: [Color(0xFFF3D68A), Color(0xFFC9A04A)]),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  kart.son4 == null ? '••••  ••••  ••••  ••••' : '••••  ••••  ••••  ${kart.son4}',
                  style: TextStyle(color: yazi, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 1.5),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        kart.takmaAd ?? banka.ad,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: yazi.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text('$kampanyaSayisi kampanya', style: TextStyle(color: yazi, fontWeight: FontWeight.w800, fontSize: 12.5)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Halka extends StatelessWidget {
  final double boyut;
  final Color renk;
  const _Halka(this.boyut, this.renk);

  @override
  Widget build(BuildContext context) => Container(
        width: boyut,
        height: boyut,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: renk.withValues(alpha: 0.10), width: 26)),
      );
}

/// Seçim ızgarasındaki küçük kart (gerçek görsel ya da kartın renkleri).
class _MiniKart extends StatelessWidget {
  final KatalogKarti k;
  const _MiniKart(this.k);

  @override
  Widget build(BuildContext context) {
    final renk = k.renk.length == 2 ? k.renk : const [Color(0xFF223152), Color(0xFF2A3A5C)];
    final yazi = Color.lerp(renk[0], renk[1], 0.5)!.computeLuminance() > 0.5 ? const Color(0xFF14171F) : Colors.white;
    final cizim = DecoratedBox(
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [renk[1], renk[0]])),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k.ad, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: yazi, fontWeight: FontWeight.w800, fontSize: 12, height: 1.15)),
            const Spacer(),
            Container(
              width: 22,
              height: 16,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(3), gradient: const LinearGradient(colors: [Color(0xFFF3D68A), Color(0xFFC9A04A)])),
            ),
          ],
        ),
      ),
    );
    return AspectRatio(
      aspectRatio: 1.586,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: k.gorsel == null ? cizim : KartGorseli(dosya: k.gorsel!, yedek: cizim),
      ),
    );
  }
}

class _BosCuzdan extends StatelessWidget {
  final VoidCallback ekle;
  const _BosCuzdan({required this.ekle});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 138,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: R.cizgi, width: 2),
              color: Colors.white.withValues(alpha: 0.03),
            ),
            child: const Icon(Icons.add_card_rounded, size: 44, color: R.soluk),
          ),
          const SizedBox(height: 20),
          Text('Cüzdanın boş', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(
            'Bankanı ve kartını seç; kart numarası istemiyoruz. Hangi kampanyanın sana uyduğunu otomatik gösterelim.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: R.soluk),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(onPressed: ekle, icon: const Icon(Icons.add_rounded), label: const Text('İlk kartını ekle')),
        ],
      ),
    );
  }
}

/// Kart ekleme / düzenleme: banka → bankanın gerçek kartları → (program) + takma ad + son 4 hane, canlı önizleme.
class _KartEkleSayfasi extends StatefulWidget {
  final KisiKarti? duzenle;
  const _KartEkleSayfasi({this.duzenle});

  @override
  State<_KartEkleSayfasi> createState() => _KartEkleSayfasiState();
}

class _KartEkleSayfasiState extends State<_KartEkleSayfasi> {
  late String? _banka = widget.duzenle?.banka;
  late String? _program = widget.duzenle?.program;
  late KatalogKarti? _kart;
  // düzenlemede ya da "listede yok" denince doğrudan ayrıntı adımı
  late bool _kartSecildi = widget.duzenle != null;
  late final _ad = TextEditingController(text: widget.duzenle?.takmaAd ?? '');
  late final _son4 = TextEditingController(text: widget.duzenle?.son4 ?? '');
  String _ara = '';
  bool _ilk = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_ilk) {
      _ilk = false;
      _kart = UygulamaKapsami.oku(context).katalog?.kart(widget.duzenle?.kartId);
    }
  }

  @override
  void dispose() {
    _ad.dispose();
    _son4.dispose();
    super.dispose();
  }

  /// Katalog kartının programı kampanya verisindeki programlardan biriyse onu seç.
  String? _eslesenProgram(KatalogKarti k, Map<String, int> pr) {
    final kp = k.program;
    if (kp == null) return null;
    if (pr.containsKey(kp)) return kp;
    final n = norm(kp);
    for (final p in pr.keys) {
      if (norm(p) == n || n.contains(norm(p)) || norm(p).contains(n)) return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final p = d.paket!;
    final t = Theme.of(context).textTheme;
    final programlar = p.programSayilari();
    final yukseklik = MediaQuery.sizeOf(context).height * 0.85;
    final klavye = MediaQuery.viewInsetsOf(context).bottom;

    Widget icerik;
    if (_banka == null) {
      final bankalar = programlar.keys.where((b) => _ara.isEmpty || norm(p.bankalar[b]!.ad).contains(norm(_ara))).toList()
        ..sort((a, b) => norm(p.bankalar[a]!.ad).compareTo(norm(p.bankalar[b]!.ad)));
      icerik = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bankanı seç', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          TextField(
            onChanged: (v) => setState(() => _ara = v),
            decoration: const InputDecoration(hintText: 'Banka ara', prefixIcon: Icon(Icons.search_rounded, color: R.soluk)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 2.3,
              ),
              itemCount: bankalar.length,
              itemBuilder: (_, i) {
                final b = p.bankalar[bankalar[i]]!;
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => setState(() {
                      _banka = b.anahtar;
                      _ara = '';
                      final pr = programlar[b.anahtar]!;
                      _program = pr.length == 1 ? pr.keys.first : null;
                      // bu bankanın kataloğu yoksa doğrudan program seçimine geç
                      _kartSecildi = (d.katalog?.banka(b.anahtar) ?? const []).isEmpty;
                    }),
                    child: Ink(
                      padding: const EdgeInsets.all(10),
                      decoration: camKutu(yaricap: 16),
                      child: Row(
                        children: [
                          BankaRozeti(b),
                          const SizedBox(width: 8),
                          Expanded(child: Text(b.ad, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else if (!_kartSecildi) {
      final banka = p.bankalar[_banka]!;
      // görselli kartlar önde; kredi kartları banka kartlarından önce
      int sira(KatalogKarti k) => (k.gorsel == null ? 2 : 0) + (k.tur == 'kredi' ? 0 : 1);
      final liste = (d.katalog?.banka(_banka!) ?? const <KatalogKarti>[])
          .where((k) => _ara.isEmpty || norm(k.ad).contains(norm(_ara)))
          .toList()
        ..sort((a, b) => sira(a).compareTo(sira(b)));
      icerik = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => setState(() => _banka = null), icon: const Icon(Icons.arrow_back_rounded)),
              Expanded(child: Text('${banka.kisa} kartın hangisi?', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            onChanged: (v) => setState(() => _ara = v),
            decoration: const InputDecoration(hintText: 'Kart ara (ör. Platinum)', prefixIcon: Icon(Icons.search_rounded, color: R.soluk)),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: liste.length + 1,
              itemBuilder: (_, i) {
                if (i == liste.length) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() {
                      _kart = null;
                      _kartSecildi = true;
                    }),
                    child: Ink(
                      decoration: camKutu(yaricap: 14),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.help_outline_rounded, color: R.soluk),
                            SizedBox(height: 6),
                            Text('Kartım listede yok', style: TextStyle(fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                final k = liste[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() {
                    _kart = k;
                    _program = _eslesenProgram(k, programlar[_banka]!) ?? _program;
                    _kartSecildi = true;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _MiniKart(k),
                        const SizedBox(height: 6),
                        Text(k.ad, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, height: 1.2)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      );
    } else {
      final banka = p.bankalar[_banka]!;
      final pr = (programlar[_banka]!.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
      final onizleme = KisiKarti(
        id: widget.duzenle?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        banka: _banka!,
        program: _program ?? pr.first.key,
        takmaAd: _ad.text.trim().isEmpty ? null : _ad.text.trim(),
        son4: _son4.text.length == 4 ? _son4.text : null,
        stil: widget.duzenle?.stil ?? 0,
        kartId: _kart?.id,
        kartAdi: _kart?.ad ?? (widget.duzenle?.kartId == null ? null : widget.duzenle?.kartAdi),
      );
      icerik = ListView(
        children: [
          Row(
            children: [
              if (widget.duzenle == null)
                IconButton(
                  onPressed: () => setState(() {
                    if ((d.katalog?.banka(_banka!) ?? const []).isEmpty) {
                      _banka = null;
                    } else {
                      _kartSecildi = false;
                    }
                  }),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              Expanded(child: Text(widget.duzenle == null ? 'Kartını tanımla' : 'Kartı düzenle', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
            ],
          ),
          const SizedBox(height: 12),
          CuzdanKarti(kart: onizleme, banka: banka, kampanyaSayisi: d.kartKampanyalari(onizleme).length),
          const SizedBox(height: 18),
          Text('Kampanya programı', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Kampanyalar bu programa göre eşleşir.', style: t.bodySmall?.copyWith(color: R.soluk)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in pr)
                ChoiceChip(
                  label: Text('${e.key}  ${e.value}'),
                  selected: (_program ?? pr.first.key) == e.key,
                  showCheckmark: false,
                  onSelected: widget.duzenle != null ? null : (_) => setState(() => _program = e.key),
                ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _ad,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            maxLength: 24,
            decoration: const InputDecoration(hintText: 'Takma ad (ör. Maaş kartım) — isteğe bağlı', counterText: ''),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _son4,
            onChanged: (_) => setState(() {}),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
            decoration: const InputDecoration(hintText: 'Son 4 hane — isteğe bağlı', prefixIcon: Icon(Icons.pin_outlined, color: R.soluk)),
          ),
          const SizedBox(height: 8),
          Text('Kart numarası istenmez. Bilgiler yalnız bu telefonda saklanır.', style: t.bodySmall?.copyWith(color: R.soluk)),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => Navigator.pop(context, onizleme),
            child: Text(widget.duzenle == null ? 'Cüzdana ekle' : 'Kaydet'),
          ),
        ],
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + klavye),
      child: SizedBox(height: yukseklik - klavye * 0.5, child: icerik),
    );
  }
}
