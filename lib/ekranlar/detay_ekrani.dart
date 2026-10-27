import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../durum.dart';
import '../ortak.dart';
import '../tema.dart';
import '../veri/katalog.dart';
import '../veri/model.dart';
import 'kampanya_karti.dart';

/// Katılım metninde "XXX yaz(ıp) NNNN'e gönder" kalıbını arar (veride hazır `sms` yoksa yedek).
final RegExp _smsKalibi = RegExp(
  r'''["“”'‘’]?\s*([A-ZÇĞİÖŞÜ0-9][A-ZÇĞİÖŞÜ0-9]{1,24}(?: [A-ZÇĞİÖŞÜ0-9]{2,24}){0,2})\s*["“”'‘’]*\s+yaz(?:ıp|ip|arak)\b[^.\n]{0,120}?\b(\d{4})\b''',
);
final RegExp _smsAlani = RegExp(r'SMS:\s*([^;]+?)\s*->\s*(\d{4})');

SmsKatilim? smsBul(Kampanya k) {
  if (k.sms != null) return k.sms;
  final m = k.katilim == null ? null : (_smsAlani.firstMatch(k.katilim!) ?? _smsKalibi.firstMatch(k.katilim!));
  if (m == null) return null;
  return SmsKatilim(kod: m.group(1)!.trim(), numara: m.group(2)!);
}

class DetayEkrani extends StatelessWidget {
  final Kampanya kampanya;
  const DetayEkrani({super.key, required this.kampanya});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final k = kampanya;
    final banka = d.paket!.bankalar[k.banka]!;
    final t = Theme.of(context).textTheme;
    final kalan = k.kalanGun(DateTime.now());
    final kalanMetin = kalanEtiket(kalan);
    final sms = smsBul(k);
    final kartimda = d.kartlarimaUyar(k);
    final ekran = MediaQuery.sizeOf(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            stretch: true,
            expandedHeight: ekran.width * 0.95,
            backgroundColor: R.zemin,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: Buzlu(
                child: IconButton(
                  tooltip: 'Geri',
                  icon: const Icon(Icons.arrow_back_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
            ),
            actions: [
              if (k.kaynakUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Buzlu(
                    child: IconButton(
                      tooltip: 'Bağlantıyı kopyala',
                      icon: const Icon(Icons.link_rounded),
                      onPressed: () => _kopyala(context, k.kaynakUrl!, 'Bağlantı kopyalandı'),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 10, 6),
                child: Buzlu(child: FavoriDugmesi(k.id)),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  KampanyaGorseli(dosya: k.gorsel, grup: k.grup),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x660F1626), Colors.transparent, R.zemin],
                        stops: [0, 0.4, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      BankaRozeti(banka, buyuk: true),
                      for (final p in k.programlar) _Cip(p),
                      _Cip(k.grup, ikon: grupIkonu(k.grup)),
                      if (kartimda) const _Cip('Kartımda', ikon: Icons.verified_rounded, renk: R.zumrut),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SelectableText(k.baslik, style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.4)),
                  if (k.odul != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(colors: [Color(0xFFFFB547), Color(0xFFFF8A47)]),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.redeem_rounded, color: R.zemin, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(k.odul!, style: t.titleLarge?.copyWith(color: R.zemin, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _BilgiKutusu(
                          ikon: Icons.event_rounded,
                          baslik: 'Bitiş',
                          deger: k.bitis == null ? '—' : tarihBicim(k.bitis!),
                          ek: kalanMetin,
                          acil: kalan != null && kalan < 3,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BilgiKutusu(
                          ikon: Icons.payments_rounded,
                          baslik: 'Min. harcama',
                          deger: k.minHarcama == null ? 'Belirtilmemiş' : tlBicim(k.minHarcama!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _BilgiKutusu(
                          ikon: Icons.play_circle_outline_rounded,
                          baslik: 'Başlangıç',
                          deger: k.baslangic == null ? '—' : tarihBicim(k.baslangic!),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _BilgiKutusu(
                          ikon: Icons.person_outline_rounded,
                          baslik: 'Segment',
                          deger: k.segment == null ? '—' : _segment(k.segment!),
                        ),
                      ),
                    ],
                  ),
                  if (k.marka != null) ...[
                    const SizedBox(height: 10),
                    _BilgiKutusu(ikon: Icons.storefront_rounded, baslik: 'Marka', deger: k.marka!),
                  ],
                  _Bolum(
                    baslik: 'Nasıl katılırım?',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.katilim ?? (k.katilimGerekli ? 'Katılım gerekli.' : 'Katılım bilgisi metinde net değil — detayı kontrol et.'),
                          style: t.bodyMedium?.copyWith(color: R.soluk, height: 1.45),
                        ),
                        if (sms != null) ...[
                          const SizedBox(height: 14),
                          _SmsKutusu(sms: sms),
                        ],
                      ],
                    ),
                  ),
                  if (k.gecerliKartlar.isNotEmpty)
                    _Bolum(baslik: 'Geçerli kartlar', child: _Maddeler(k.gecerliKartlar, ikon: Icons.check_circle_rounded, renk: R.zumrut)),
                  if (k.haricKartlar.isNotEmpty)
                    _Bolum(baslik: 'Hariç / dahil olmayanlar', child: _Maddeler(k.haricKartlar, ikon: Icons.block_rounded, renk: R.mercan)),
                  if (k.detay.isNotEmpty) _Bolum(baslik: 'Kampanya metni', child: _AcilirMetin(k.detay)),
                  const SizedBox(height: 18),
                  Text(
                    'Bilgiler bankanın sitesinden otomatik derlendi; katılmadan önce koşulları kaynakta doğrula.',
                    style: t.bodySmall?.copyWith(color: R.soluk),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: k.kaynakUrl == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: FilledButton.icon(
                  onPressed: () => _ac(context, Uri.parse(k.kaynakUrl!)),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: Text('${banka.kisa} sitesinde aç'),
                ),
              ),
            ),
    );
  }

  static String _segment(String s) => switch (s) {
        'bireysel' => 'Bireysel',
        'ticari' => 'Ticari',
        'bireysel+ticari' => 'Bireysel + Ticari',
        _ => s,
      };
}

class _Cip extends StatelessWidget {
  final String metin;
  final IconData? ikon;
  final Color? renk;
  const _Cip(this.metin, {this.ikon, this.renk});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (renk ?? Colors.white).withValues(alpha: renk == null ? 0.08 : 0.16),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (ikon != null) ...[Icon(ikon, size: 14, color: renk ?? R.soluk), const SizedBox(width: 4)],
            Text(metin, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: renk ?? R.yazi)),
          ],
        ),
      );
}

class _BilgiKutusu extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String deger;
  final String? ek;
  final bool acil;
  const _BilgiKutusu({required this.ikon, required this.baslik, required this.deger, this.ek, this.acil = false});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: camKutu(yaricap: 18),
        child: Row(
          children: [
            Icon(ikon, color: R.zumrut, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(baslik, style: const TextStyle(fontSize: 11.5, color: R.soluk)),
                  Text(deger, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  if (ek != null)
                    Text(ek!, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: acil ? R.mercan : R.amber)),
                ],
              ),
            ),
          ],
        ),
      );
}

/// Uzun kampanya metni: ilk 6 satır, "Tamamını göster" ile açılır.
class _AcilirMetin extends StatefulWidget {
  final String metin;
  const _AcilirMetin(this.metin);

  @override
  State<_AcilirMetin> createState() => _AcilirMetinState();
}

class _AcilirMetinState extends State<_AcilirMetin> {
  bool _acik = false;

  @override
  Widget build(BuildContext context) {
    final st = Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5, color: R.soluk);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _acik ? SelectableText(widget.metin, style: st) : Text(widget.metin, style: st, maxLines: 6, overflow: TextOverflow.fade),
        TextButton(onPressed: () => setState(() => _acik = !_acik), child: Text(_acik ? 'Daralt' : 'Tamamını göster')),
      ],
    );
  }
}

/// Sağa kaydırınca işi yapan hap düğme (yanlışlıkla dokunmaya karşı). %85'i geçince tetikler, yoksa geri yaylanır.
class KaydirDugmesi extends StatefulWidget {
  final String metin;
  final IconData ikon;
  final Future<void> Function() tamam;
  const KaydirDugmesi({super.key, required this.metin, required this.ikon, required this.tamam});

  @override
  State<KaydirDugmesi> createState() => _KaydirDugmesiState();
}

class _KaydirDugmesiState extends State<KaydirDugmesi> with SingleTickerProviderStateMixin {
  late final AnimationController _geri = AnimationController(vsync: this, duration: const Duration(milliseconds: 220))
    ..addListener(() => setState(() => _x = _baslangic * (1 - Curves.easeOut.transform(_geri.value))));
  double _x = 0, _baslangic = 0;
  bool _bitti = false;

  @override
  void dispose() {
    _geri.dispose();
    super.dispose();
  }

  void _yaylan() {
    _baslangic = _x;
    _geri.forward(from: 0);
  }

  Future<void> _birak(double maks) async {
    if (_x < maks * 0.85) return _yaylan();
    setState(() {
      _x = maks;
      _bitti = true;
    });
    HapticFeedback.mediumImpact();
    await widget.tamam();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _bitti = false);
    _yaylan();
  }

  @override
  Widget build(BuildContext context) {
    const h = 60.0;
    return LayoutBuilder(builder: (context, c) {
      final maks = c.maxWidth - h;
      final oran = maks <= 0 ? 0.0 : (_x / maks).clamp(0.0, 1.0);
      return Container(
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          gradient: LinearGradient(colors: [R.zumrut.withValues(alpha: 0.25 + 0.5 * oran), R.yuzey2]),
          border: Border.all(color: R.zumrut.withValues(alpha: 0.5)),
        ),
        child: Stack(
          children: [
            Center(
              child: Opacity(
                opacity: _bitti ? 1 : 1 - oran,
                child: Padding(
                  padding: const EdgeInsets.only(left: h * 0.8),
                  child: Text(_bitti ? 'Mesaj uygulaması açılıyor' : widget.metin, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
            Positioned(
              left: _x,
              child: GestureDetector(
                onHorizontalDragUpdate: _bitti ? null : (e) => setState(() => _x = (_x + e.delta.dx).clamp(0.0, maks)),
                onHorizontalDragEnd: _bitti ? null : (_) => _birak(maks),
                child: Container(
                  width: h,
                  height: h,
                  decoration: const BoxDecoration(color: R.zumrut, shape: BoxShape.circle),
                  child: Icon(_bitti ? Icons.check_rounded : widget.ikon, color: R.zemin),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

Future<void> _ac(BuildContext context, Uri uri) async {
  final m = ScaffoldMessenger.of(context);
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) m.showSnackBar(const SnackBar(content: Text('Açılamadı')));
  } catch (_) {
    m.showSnackBar(const SnackBar(content: Text('Açılamadı')));
  }
}

const _smsKanal = MethodChannel('kampanyabul/sms');

/// Doğrudan varsayılan SMS uygulaması (seçici yok); olmazsa sms: bağlantısına düşer.
Future<void> _smsAc(BuildContext context, SmsKatilim sms) async {
  try {
    if (await _smsKanal.invokeMethod<bool>('ac', {'numara': sms.numara, 'govde': sms.govde}) == true) return;
  } catch (_) {}
  // iOS gövdeyi '&body=' ile, Android '?body=' ile okur
  final ayrac = Platform.isIOS ? '&' : '?';
  if (context.mounted) await _ac(context, Uri.parse('sms:${sms.numara}${ayrac}body=${Uri.encodeComponent(sms.govde)}'));
}

void _kopyala(BuildContext context, String metin, String mesaj) {
  Clipboard.setData(ClipboardData(text: metin));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)));
}

class _SmsKutusu extends StatelessWidget {
  final SmsKatilim sms;
  const _SmsKutusu({required this.sms});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: camKutu(vurgulu: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(text: sms.kod, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: 1)),
                    TextSpan(text: '   →   ', style: t.titleMedium?.copyWith(color: R.soluk)),
                    TextSpan(text: sms.numara, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, color: R.zumrut)),
                  ]),
                ),
              ),
              IconButton(
                tooltip: 'Kodu kopyala',
                onPressed: () => _kopyala(context, sms.kod, 'Kod kopyalandı: ${sms.kod}'),
                icon: const Icon(Icons.copy_rounded, size: 20),
              ),
            ],
          ),
          if (sms.ek != null) ...[
            const SizedBox(height: 2),
            Text('Kodun ardına bir boşluk bırakıp ekle: ${sms.ek}', style: t.bodySmall?.copyWith(color: R.amber)),
          ],
          const SizedBox(height: 12),
          // Yalnız mesaj uygulamasını hazır metinle açar; gönderme kullanıcıda.
          KaydirDugmesi(metin: "Kaydır, SMS'i hazırla", ikon: Icons.sms_rounded, tamam: () => _smsAc(context, sms)),
        ],
      ),
    );
  }
}

class _Bolum extends StatelessWidget {
  final String baslik;
  final Widget child;
  const _Bolum({required this.baslik, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _Maddeler extends StatelessWidget {
  final List<String> maddeler;
  final IconData ikon;
  final Color renk;
  const _Maddeler(this.maddeler, {required this.ikon, required this.renk});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final m in maddeler)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(padding: const EdgeInsets.only(top: 2), child: Icon(ikon, size: 16, color: renk)),
                const SizedBox(width: 8),
                Expanded(child: Text(m, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
