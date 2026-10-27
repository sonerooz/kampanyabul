import 'package:flutter/material.dart';

import '../durum.dart';
import '../hesap.dart';
import '../ortak.dart';
import '../tema.dart';
import 'kampanya_karti.dart';

/// Profil: avatar + ad, giriş (Google / Facebook), özet kutuları, favoriler ve uygulama bilgileri.
class ProfilEkrani extends StatelessWidget {
  final VoidCallback kartlarimaGit;
  final void Function({String? grup, bool arama}) kampanyalaraGit;
  const ProfilEkrani({super.key, required this.kartlarimaGit, required this.kampanyalaraGit});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final p = d.paket!;
    final t = Theme.of(context).textTheme;
    final pr = d.profil;
    final bugun = DateTime.now();
    final acik = p.kampanyalar.where((k) => (k.kalanGun(bugun) ?? 0) >= 0).toList();
    final uygun = acik.where(d.kartlarimaUyar).length;
    final buHafta = acik.where((k) => d.kartlarimaUyar(k) && (k.kalanGun(bugun) ?? 99) <= 7).length;
    final alt = MediaQuery.paddingOf(context).bottom + 110;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.only(bottom: alt),
        children: [
          // Başlık: kapak görselinin üstünde avatar
          SizedBox(
            height: 300,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ShaderMask(
                  shaderCallback: (r) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white, Colors.transparent],
                    stops: [0.2, 1],
                  ).createShader(r),
                  blendMode: BlendMode.dstIn,
                  child: Image.asset('assets/gorsel/kapak.webp', fit: BoxFit.cover, alignment: const Alignment(0, -0.2)),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProfilResmi(foto: pr?.foto, bas: pr?.bas ?? 'K', boyut: 96),
                      const SizedBox(height: 10),
                      Text(pr?.ad ?? 'Misafir', style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        pr == null ? 'Giriş yapmadan kullanıyorsun' : (pr.eposta ?? '${pr.saglayiciAdi} hesabı'),
                        style: t.bodyMedium?.copyWith(color: R.soluk),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (pr == null)
            const Padding(padding: EdgeInsets.fromLTRB(16, 18, 16, 0), child: SosyalGirisDugmeleri())
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: R.zumrut.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_rounded, size: 16, color: R.zumrut),
                      const SizedBox(width: 6),
                      Text('${pr.saglayiciAdi} ile bağlı', style: const TextStyle(color: R.zumrut, fontWeight: FontWeight.w700, fontSize: 12.5)),
                    ],
                  ),
                ),
              ),
            ),
          const BolumBasligi('Özetin'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _OzetKutusu(ikon: Icons.credit_card_rounded, deger: '${d.cuzdan.length}', baslik: 'Kart', renk: R.zumrut, onTap: kartlarimaGit)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OzetKutusu(
                        ikon: Icons.bookmark_rounded,
                        deger: '${d.favoriler.length}',
                        baslik: 'Favori',
                        renk: R.amber,
                        onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FavorilerEkrani())),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OzetKutusu(
                        ikon: Icons.local_offer_rounded,
                        deger: '$uygun',
                        baslik: 'Sana uygun kampanya',
                        renk: const Color(0xFF7FB2FF),
                        onTap: () {
                          d.sadeceKartlarim = true;
                          kampanyalaraGit();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OzetKutusu(
                        ikon: Icons.local_fire_department_rounded,
                        deger: '$buHafta',
                        baslik: '7 gün içinde bitiyor',
                        renk: R.mercan,
                        onTap: () {
                          d.sadeceKartlarim = true;
                          kampanyalaraGit();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const BolumBasligi('Hesap ve uygulama'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: camKutu(),
            child: Column(
              children: [
                _Satir(
                  ikon: Icons.bookmark_border_rounded,
                  baslik: 'Favorilerim',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const FavorilerEkrani())),
                ),
                _Satir(ikon: Icons.credit_card_rounded, baslik: 'Kartlarım', onTap: kartlarimaGit),
                _Satir(
                  ikon: Icons.cloud_done_outlined,
                  baslik: 'Veri tarihi',
                  alt: '${isoBicim(p.uretim)} · ${acik.length} açık kampanya · ${p.bankalar.length} banka/cüzdan',
                ),
                _Satir(
                  ikon: Icons.shield_outlined,
                  baslik: 'Gizlilik',
                  alt: 'Kartların ve favorilerin yalnız bu telefonda. Girişte ad/e-posta, ayrıca anonim hata kayıtları KampanyaBul sunucusuna gider.',
                ),
                _Satir(
                  ikon: Icons.info_outline_rounded,
                  baslik: 'KampanyaBul',
                  alt: 'Kişisel kullanım. Veriler bankaların herkese açık sayfalarından derlenir.',
                  son: pr == null,
                ),
                if (pr != null)
                  _Satir(
                    ikon: Icons.logout_rounded,
                    baslik: 'Çıkış yap',
                    renk: R.mercan,
                    son: true,
                    onTap: () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Çıkış yapılsın mı?'),
                          content: const Text('Kartların ve favorilerin bu telefonda kalır.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Vazgeç')),
                            FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Çıkış yap')),
                          ],
                        ),
                      );
                      if (ok == true) await d.cikisYap();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Google ve Facebook giriş düğmeleri (Emlak Deal tarzı: beyaz Google, mavi Facebook hapları).
class SosyalGirisDugmeleri extends StatefulWidget {
  final VoidCallback? sonra;
  const SosyalGirisDugmeleri({super.key, this.sonra});

  @override
  State<SosyalGirisDugmeleri> createState() => _SosyalGirisDugmeleriState();
}

class _SosyalGirisDugmeleriState extends State<SosyalGirisDugmeleri> {
  String? _bekleyen;

  Future<void> _giris(String saglayici) async {
    if (_bekleyen != null) return;
    setState(() => _bekleyen = saglayici);
    final d = UygulamaKapsami.oku(context);
    final m = ScaffoldMessenger.of(context);
    final r = saglayici == 'google' ? await SosyalGiris.google() : await SosyalGiris.facebook();
    if (!mounted) return;
    setState(() => _bekleyen = null);
    if (r.profil != null) {
      d.girisYapildi(r.profil!);
      m.showSnackBar(SnackBar(content: Text('Hoş geldin, ${r.profil!.ad.split(' ').first}!')));
      widget.sonra?.call();
    } else if (r.hata != null) {
      m.showSnackBar(SnackBar(content: Text(r.hata!), duration: const Duration(seconds: 5)));
    }
  }

  Widget _dugme({required String saglayici, required String metin, required Color zemin, required Color yazi, required Widget ikon}) => SizedBox(
        height: 54,
        child: Material(
          color: zemin,
          shape: const StadiumBorder(),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: () => _giris(saglayici),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_bekleyen == saglayici)
                  SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: yazi))
                else
                  ikon,
                const SizedBox(width: 12),
                Text(metin, style: TextStyle(color: yazi, fontWeight: FontWeight.w700, fontSize: 15)),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Column(
        children: [
          _dugme(
            saglayici: 'google',
            metin: 'Google ile devam et',
            zemin: Colors.white,
            yazi: const Color(0xFF1F1F1F),
            ikon: const SizedBox(width: 22, height: 22, child: CustomPaint(painter: _GoogleG())),
          ),
          const SizedBox(height: 12),
          _dugme(
            saglayici: 'facebook',
            metin: 'Facebook ile devam et',
            zemin: R.facebook,
            yazi: Colors.white,
            ikon: const Icon(Icons.facebook_rounded, color: Colors.white, size: 24),
          ),
        ],
      );
}

/// Dört renkli "G" (Google'ın resmî düğme yönergesine uygun basit çizim).
class _GoogleG extends CustomPainter {
  const _GoogleG();

  @override
  void paint(Canvas canvas, Size s) {
    final r = Rect.fromLTWH(s.width * 0.1, s.height * 0.1, s.width * 0.8, s.height * 0.8);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.18;
    const tam = 6.283185307;
    void yay(Color c, double bas, double sup) => canvas.drawArc(r, bas * tam, sup * tam, false, p..color = c);
    yay(const Color(0xFFEA4335), 0.62, 0.26); // kırmızı (üst)
    yay(const Color(0xFFFBBC05), 0.38, 0.24); // sarı (sol)
    yay(const Color(0xFF34A853), 0.14, 0.24); // yeşil (alt)
    yay(const Color(0xFF4285F4), 0.0, 0.14); // mavi (sağ alt)
    canvas.drawLine(Offset(s.width * 0.5, s.height * 0.5), Offset(s.width * 0.9, s.height * 0.5), p..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _OzetKutusu extends StatelessWidget {
  final IconData ikon;
  final String deger;
  final String baslik;
  final Color renk;
  final VoidCallback? onTap;
  const _OzetKutusu({required this.ikon, required this.deger, required this.baslik, required this.renk, this.onTap});

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            height: 118,
            padding: const EdgeInsets.all(16),
            decoration: camKutu(yaricap: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: renk.withValues(alpha: 0.16), shape: BoxShape.circle),
                  child: Icon(ikon, color: renk, size: 20),
                ),
                const Spacer(),
                Text(deger, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: renk, height: 1)),
                const SizedBox(height: 4),
                Text(baslik, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: R.soluk, fontSize: 12.5)),
              ],
            ),
          ),
        ),
      );
}

class _Satir extends StatelessWidget {
  final IconData ikon;
  final String baslik;
  final String? alt;
  final VoidCallback? onTap;
  final Color? renk;
  final bool son;
  const _Satir({required this.ikon, required this.baslik, this.alt, this.onTap, this.renk, this.son = false});

  @override
  Widget build(BuildContext context) => Column(
        children: [
          ListTile(
            leading: Icon(ikon, color: renk ?? R.soluk),
            title: Text(baslik, style: TextStyle(fontWeight: FontWeight.w700, color: renk)),
            subtitle: alt == null ? null : Text(alt!, style: const TextStyle(color: R.soluk, fontSize: 12.5)),
            trailing: onTap == null ? null : const Icon(Icons.chevron_right_rounded, color: R.soluk),
            onTap: onTap,
          ),
          if (!son) const Divider(indent: 56, endIndent: 16),
        ],
      );
}

/// Favoriye eklenen kampanyalar.
class FavorilerEkrani extends StatelessWidget {
  const FavorilerEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final l = d.favoriKampanyalar;
    final bugun = DateTime.now();
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Favorilerim')),
      body: l.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bookmark_border_rounded, size: 56, color: R.soluk),
                    const SizedBox(height: 12),
                    Text('Henüz favori yok', style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('Kampanya detayında yer imine dokunarak buraya ekleyebilirsin.',
                        textAlign: TextAlign.center, style: t.bodyMedium?.copyWith(color: R.soluk)),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: l.length,
              itemBuilder: (_, i) => KampanyaSatiri(kampanya: l[i], banka: d.paket!.bankalar[l[i].banka]!, bugun: bugun),
            ),
    );
  }
}
