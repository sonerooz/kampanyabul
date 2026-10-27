import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kampanyabul/ekranlar/detay_ekrani.dart';
import 'package:kampanyabul/veri/model.dart';
import 'package:kampanyabul/veri/normalize.dart';

void main() {
  test('Türkçe normalizasyon', () {
    expect(norm('AKARYAKIT'), 'akaryakit');
    expect(norm('İdefix\'te Şık Ödül'), 'idefix te sik odul');
    expect(norm('Marks & Spencer'), 'marks ve spencer');
  });

  test('Asset JSON çözülür, arama çalışır', () {
    final j = jsonDecode(File('assets/kampanyalar.json').readAsStringSync()) as Map<String, dynamic>;
    final p = VeriPaketi.fromJson(j);
    expect(p.kampanyalar.length, greaterThan(1000));
    expect(p.bankalar.length, greaterThan(10));
    final opet = p.kampanyalar.where((k) => k.eslesir(sorguKelimeleri('opet'))).toList();
    expect(opet, isNotEmpty);
    final akaryakit = p.kampanyalar.where((k) => k.eslesir(sorguKelimeleri('Akaryakıt'))).length;
    expect(akaryakit, greaterThan(10));
    final sms = p.kampanyalar.where((k) => smsBul(k) != null).length;
    expect(sms, greaterThan(50));
    // ignore: avoid_print
    print('kampanya=${p.kampanyalar.length} opet=${opet.length} akaryakit=$akaryakit sms=$sms '
        'idefix=${p.kampanyalar.where((k) => k.eslesir(sorguKelimeleri('idefix'))).length}');
  });
}
