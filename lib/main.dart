import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'durum.dart';
import 'ekranlar/giris_ekrani.dart';
import 'ekranlar/kampanyalar_ekrani.dart';
import 'ekranlar/kartlarim_ekrani.dart';
import 'ekranlar/kesfet_ekrani.dart';
import 'ekranlar/profil_ekrani.dart';
import 'sunucu.dart';
import 'tema.dart';
import 'veri/veri_kaynagi.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: R.zemin,
  ));
  // çökme / yakalanmamış hatalar sunucu loguna
  final onceki = FlutterError.onError;
  FlutterError.onError = (d) {
    Sunucu.olay('hata', 'flutter', '${d.exceptionAsString()}\n${d.stack}');
    onceki?.call(d);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    Sunucu.olay('hata', 'platform', '$e\n$st');
    return false;
  };
  Sunucu.olay('olay', 'acilis');
  final durum = UygulamaDurumu(const SunucuVeriKaynagi())..baslat();
  runApp(KampanyaBulApp(durum: durum));
}

class KampanyaBulApp extends StatelessWidget {
  final UygulamaDurumu durum;
  const KampanyaBulApp({super.key, required this.durum});

  @override
  Widget build(BuildContext context) {
    return UygulamaKapsami(
      durum: durum,
      child: MaterialApp(
        title: 'KampanyaBul',
        debugShowCheckedModeBanner: false,
        theme: uygulamaTemasi(),
        themeMode: ThemeMode.dark,
        locale: const Locale('tr', 'TR'),
        supportedLocales: const [Locale('tr', 'TR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const _Kabuk(),
      ),
    );
  }
}

class _Kabuk extends StatefulWidget {
  const _Kabuk();

  @override
  State<_Kabuk> createState() => _KabukState();
}

class _KabukState extends State<_Kabuk> {
  int _sekme = 0;
  final _kampanyalar = GlobalKey<KampanyalarEkraniState>();

  void _git(int i) => setState(() => _sekme = i);

  void _kampanyalaraGit({String? grup, bool arama = false}) {
    final d = UygulamaKapsami.oku(context);
    if (grup != null || !arama) d.grup = grup;
    _git(1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _kampanyalar.currentState?.basaDon();
      if (arama) _kampanyalar.currentState?.aramayaOdaklan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    if (!d.yuklendi) {
      return Scaffold(
        body: Center(
          child: d.hata == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Kampanyalar yükleniyor…')],
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48),
                      const SizedBox(height: 12),
                      Text('Veri yüklenemedi:\n${d.hata}', textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: d.yenidenYukle, child: const Text('Tekrar dene')),
                    ],
                  ),
                ),
        ),
      );
    }
    if (!d.girisGoruldu) return const GirisEkrani();

    return PopScope(
      canPop: _sekme == 0,
      onPopInvokedWithResult: (pop, _) {
        if (!pop) _git(0);
      },
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _sekme,
          children: [
            KesfetEkrani(kampanyalaraGit: _kampanyalaraGit, kartlarimaGit: () => _git(2), profileGit: () => _git(3)),
            KampanyalarEkrani(key: _kampanyalar, kartlarimaGit: () => _git(2)),
            const KartlarimEkrani(),
            ProfilEkrani(kartlarimaGit: () => _git(2), kampanyalaraGit: _kampanyalaraGit),
          ],
        ),
        bottomNavigationBar: _AltMenu(
          secili: _sekme,
          sec: _git,
          kartSayisi: d.cuzdan.length,
        ),
      ),
    );
  }
}

/// Yüzen, buzlu cam alt menü; seçili sekme zümrüt hap.
class _AltMenu extends StatelessWidget {
  final int secili;
  final ValueChanged<int> sec;
  final int kartSayisi;
  const _AltMenu({required this.secili, required this.sec, required this.kartSayisi});

  static const _ogeler = [
    (Icons.explore_outlined, Icons.explore_rounded, 'Keşfet'),
    (Icons.local_offer_outlined, Icons.local_offer_rounded, 'Kampanyalar'),
    (Icons.credit_card_outlined, Icons.credit_card_rounded, 'Kartlarım'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Buzlu(
          yaricap: 32,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              for (var i = 0; i < _ogeler.length; i++)
                Expanded(
                  flex: i == secili ? 3 : 2,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => sec(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      height: 52,
                      decoration: BoxDecoration(
                        color: i == secili ? R.zumrut : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Badge(
                            isLabelVisible: i == 2 && kartSayisi > 0 && i != secili,
                            backgroundColor: R.amber,
                            textColor: R.zemin,
                            label: Text('$kartSayisi'),
                            child: Icon(i == secili ? _ogeler[i].$2 : _ogeler[i].$1, color: i == secili ? R.zemin : R.soluk),
                          ),
                          if (i == secili) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                _ogeler[i].$3,
                                maxLines: 1,
                                overflow: TextOverflow.fade,
                                softWrap: false,
                                style: const TextStyle(color: R.zemin, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            ),
                          ],
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
