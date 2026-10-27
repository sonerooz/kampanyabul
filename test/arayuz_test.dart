import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kampanyabul/durum.dart';
import 'package:kampanyabul/ekranlar/detay_ekrani.dart';
import 'package:kampanyabul/main.dart';
import 'package:kampanyabul/veri/model.dart';
import 'package:kampanyabul/veri/veri_kaynagi.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DosyaKaynagi extends VeriKaynagi {
  final VeriPaketi paket;
  const _DosyaKaynagi(this.paket);
  @override
  String get aciklama => 'test';
  @override
  Future<VeriPaketi> yukle() async => paket;
}

void main() {
  testWidgets('Ana ekran, arama, detay, kartlarım, ayarlar açılır', (tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final paket = VeriPaketi.fromJson(
        jsonDecode(File('assets/kampanyalar.json').readAsStringSync()) as Map<String, dynamic>);
    final durum = UygulamaDurumu(_DosyaKaynagi(paket));
    await durum.baslat();
    await tester.pumpWidget(KampanyaBulApp(durum: durum));
    await tester.pumpAndSettle();
    expect(find.text('KampanyaBul'), findsOneWidget);
    expect(find.textContaining('kampanya'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'opet');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(durum.sonuc, isNotEmpty);
    expect(durum.sonuc.length, lessThan(paket.kampanyalar.length));

    // SMS'li bir kampanyanın detayını aç
    await tester.enterText(find.byType(TextField), 'CarrefourSA');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Card).first);
    await tester.pumpAndSettle();
    expect(find.text('Katılım'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Kaynakta aç'), 300, scrollable: find.descendant(of: find.byType(DetayEkrani), matching: find.byType(Scrollable)).first);
    expect(find.text('Kaynakta aç'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // Sadece kartlarım, seçim yokken uyarı
    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    expect(find.byType(MaterialBanner), findsOneWidget);

    // Kartlarım sekmesi
    await tester.tap(find.text('Kartlarım').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    expect(durum.kartlar, isNotEmpty);

    // Ayarlar
    await tester.tap(find.text('Ayarlar').last);
    await tester.pumpAndSettle();
    expect(find.text('Veri tarihi'), findsOneWidget);

    // Banka filtresi alt sayfası
    await tester.tap(find.text('Kampanyalar').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Banka filtresi'));
    await tester.pumpAndSettle();
    expect(find.text('Bankalar'), findsOneWidget);
    await tester.tap(find.textContaining('İş Bankası').last);
    await tester.pump();
    await tester.tap(find.textContaining('Uygula'));
    await tester.pumpAndSettle();
    expect(durum.bankaFiltresi.length, 1);
  });
}
