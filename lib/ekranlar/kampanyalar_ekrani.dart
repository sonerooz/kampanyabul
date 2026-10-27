import '../veri/katalog.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../durum.dart';
import '../ortak.dart';
import '../tema.dart';
import '../veri/model.dart';
import 'kampanya_karti.dart';

/// Tüm kampanyalar: arama, kategori, banka, sıralama, kartlarım filtresi; liste / ızgara görünümü.
class KampanyalarEkrani extends StatefulWidget {
  final VoidCallback kartlarimaGit;
  const KampanyalarEkrani({super.key, required this.kartlarimaGit});

  @override
  State<KampanyalarEkrani> createState() => KampanyalarEkraniState();
}

class KampanyalarEkraniState extends State<KampanyalarEkrani> {
  final _arama = TextEditingController();
  final _odak = FocusNode();
  final _liste = ScrollController();
  Timer? _bekle;

  @override
  void initState() {
    super.initState();
    _arama.text = UygulamaKapsami.oku(context).sorgu;
  }

  @override
  void dispose() {
    _bekle?.cancel();
    _arama.dispose();
    _odak.dispose();
    _liste.dispose();
    super.dispose();
  }

  /// Keşfet'teki arama kutusundan gelince klavyeyi aç.
  void aramayaOdaklan() {
    _arama.text = UygulamaKapsami.oku(context).sorgu;
    _odak.requestFocus();
  }

  void basaDon() {
    if (_liste.hasClients) _liste.jumpTo(0);
  }

  void _aramaDegisti(String v) {
    setState(() {});
    _bekle?.cancel();
    _bekle = Timer(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      UygulamaKapsami.oku(context).sorgu = v;
      basaDon();
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final p = d.paket!;
    final t = Theme.of(context).textTheme;
    final bugun = DateTime.now();
    final kartUyarisi = d.sadeceKartlarim && d.kartlar.isEmpty;
    final alt = MediaQuery.paddingOf(context).bottom + 100;

    final ust = <Widget>[
      SliverToBoxAdapter(
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 0),
            child: Row(
              children: [
                Expanded(child: Text('Kampanyalar', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5))),
                IconButton(
                  tooltip: d.izgara ? 'Liste görünümü' : 'Büyük kart görünümü',
                  onPressed: () => d.izgara = !d.izgara,
                  icon: Icon(d.izgara ? Icons.view_agenda_outlined : Icons.grid_view_rounded),
                ),
                IconButton(
                  tooltip: 'Banka filtresi',
                  onPressed: () => _bankaFiltresiAc(context),
                  icon: Badge(
                    isLabelVisible: d.bankaFiltresi.isNotEmpty,
                    backgroundColor: R.amber,
                    textColor: R.zemin,
                    label: Text('${d.bankaFiltresi.length}'),
                    child: const Icon(Icons.account_balance_outlined),
                  ),
                ),
                PopupMenuButton<Siralama>(
                  tooltip: 'Sıralama',
                  icon: const Icon(Icons.swap_vert_rounded),
                  initialValue: d.siralama,
                  onSelected: (s) {
                    d.siralama = s;
                    basaDon();
                  },
                  itemBuilder: (_) => [
                    for (final s in Siralama.values) CheckedPopupMenuItem(value: s, checked: s == d.siralama, child: Text(s.etiket)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _arama,
            focusNode: _odak,
            onChanged: _aramaDegisti,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Mağaza, marka ya da kelime (opet, idefix…)',
              prefixIcon: const Icon(Icons.search_rounded, color: R.soluk),
              suffixIcon: _arama.text.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Temizle',
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _arama.clear();
                        _aramaDegisti('');
                      },
                    ),
            ),
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            children: [
              _GrupCipi(
                etiket: 'Tümü',
                sayi: d.grupsuzToplam,
                secili: d.grup == null,
                onTap: () {
                  d.grup = null;
                  basaDon();
                },
              ),
              for (final g in p.gruplar)
                if ((d.grupSayilari[g] ?? 0) > 0 || d.grup == g)
                  _GrupCipi(
                    etiket: g,
                    gorsel: grupGorseli(g),
                    sayi: d.grupSayilari[g] ?? 0,
                    secili: d.grup == g,
                    onTap: () {
                      d.grup = d.grup == g ? null : g;
                      basaDon();
                    },
                  ),
            ],
          ),
        ),
      ),
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 12, 4),
          child: Row(
            children: [
              Expanded(child: Text('${d.sonuc.length} kampanya', style: t.labelLarge?.copyWith(color: R.soluk))),
              FilterChip(
                avatar: const Icon(Icons.credit_card_rounded, size: 16),
                label: const Text('Kartlarım'),
                selected: d.sadeceKartlarim,
                showCheckmark: false,
                onSelected: (v) {
                  d.sadeceKartlarim = v;
                  basaDon();
                },
              ),
            ],
          ),
        ),
      ),
      if (kartUyarisi)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            padding: const EdgeInsets.all(14),
            decoration: camKutu(renk: R.zumrutKoyu),
            child: Row(
              children: [
                const Icon(Icons.add_card_rounded, color: Colors.white),
                const SizedBox(width: 12),
                const Expanded(child: Text('Henüz kart eklemedin. Kartını ekle, sadece sana uyan kampanyalar listelensin.')),
                TextButton(
                  onPressed: widget.kartlarimaGit,
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                  child: const Text('Ekle'),
                ),
              ],
            ),
          ),
        ),
    ];

    Widget govde;
    if (d.sonuc.isEmpty) {
      govde = SliverFillRemaining(hasScrollBody: false, child: _BosListe(kartUyarisi: kartUyarisi, sorgu: d.sorgu));
    } else if (d.izgara) {
      govde = SliverPadding(
        padding: EdgeInsets.fromLTRB(16, 10, 16, alt),
        sliver: SliverGrid.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.62,
          ),
          itemCount: d.sonuc.length,
          itemBuilder: (_, i) {
            final k = d.sonuc[i];
            return KampanyaVitrini(key: ValueKey(k.id), kampanya: k, banka: p.bankalar[k.banka]!, bugun: bugun);
          },
        ),
      );
    } else {
      govde = SliverPadding(
        padding: EdgeInsets.only(top: 6, bottom: alt),
        sliver: SliverList.builder(
          itemCount: d.sonuc.length,
          itemBuilder: (_, i) {
            final k = d.sonuc[i];
            return KampanyaSatiri(key: ValueKey(k.id), kampanya: k, banka: p.bankalar[k.banka]!, bugun: bugun);
          },
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(controller: _liste, slivers: [...ust, govde]),
    );
  }

  Future<void> _bankaFiltresiAc(BuildContext context) async {
    final d = UygulamaKapsami.oku(context);
    final secim = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _BankaFiltreSayfasi(paket: d.paket!, baslangic: d.bankaFiltresi),
    );
    if (secim != null) {
      d.bankaFiltresiAyarla(secim);
      basaDon();
    }
  }
}

class _GrupCipi extends StatelessWidget {
  final String etiket;
  final String? gorsel;
  final int sayi;
  final bool secili;
  final VoidCallback onTap;
  const _GrupCipi({required this.etiket, this.gorsel, required this.sayi, required this.secili, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: gorsel == null ? null : CircleAvatar(backgroundImage: AssetImage(gorsel!)),
        label: Text('$etiket  $sayi'),
        selected: secili,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _BosListe extends StatelessWidget {
  final bool kartUyarisi;
  final String sorgu;
  const _BosListe({required this.kartUyarisi, required this.sorgu});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 140),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ClipOval(child: GrupGorseli('Diğer', genislik: 120, yukseklik: 120)),
          const SizedBox(height: 18),
          Text(
            kartUyarisi ? 'Kart eklenmedi' : 'Sonuç yok',
            style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            kartUyarisi
                ? 'Kartlarına uyan kampanyaları görmek için önce kartını ekle.'
                : sorgu.isEmpty
                    ? 'Bu filtrelerle kampanya bulunamadı.'
                    : '"$sorgu" için kampanya bulunamadı.',
            textAlign: TextAlign.center,
            style: t.bodyMedium?.copyWith(color: R.soluk),
          ),
        ],
      ),
    );
  }
}

class _BankaFiltreSayfasi extends StatefulWidget {
  final VeriPaketi paket;
  final Set<String> baslangic;
  const _BankaFiltreSayfasi({required this.paket, required this.baslangic});

  @override
  State<_BankaFiltreSayfasi> createState() => _BankaFiltreSayfasiState();
}

class _BankaFiltreSayfasiState extends State<_BankaFiltreSayfasi> {
  late final Set<String> _secim = {...widget.baslangic};

  @override
  Widget build(BuildContext context) {
    final p = widget.paket;
    final sayilar = <String, int>{};
    for (final k in p.kampanyalar) {
      sayilar[k.banka] = (sayilar[k.banka] ?? 0) + 1;
    }
    final bankalar = p.bankalar.values.where((b) => (sayilar[b.anahtar] ?? 0) > 0).toList()
      ..sort((a, b) => (sayilar[b.anahtar]!).compareTo(sayilar[a.anahtar]!));
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bankalar', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text('Seçim yoksa tüm bankalar gösterilir.', style: t.bodySmall?.copyWith(color: R.soluk)),
            const SizedBox(height: 14),
            Flexible(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in bankalar)
                      FilterChip(
                        avatar: CircleAvatar(backgroundColor: b.renk, radius: 6),
                        label: Text('${b.ad}  ${sayilar[b.anahtar]}'),
                        selected: _secim.contains(b.anahtar),
                        showCheckmark: false,
                        onSelected: (v) => setState(() => v ? _secim.add(b.anahtar) : _secim.remove(b.anahtar)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: () => setState(_secim.clear), child: const Text('Temizle')),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.pop(context, _secim),
                  child: Text(_secim.isEmpty ? 'Tümünü göster' : 'Uygula (${_secim.length})'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
