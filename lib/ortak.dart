import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'veri/model.dart';

const _aylar = [
  'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
  'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
];

final NumberFormat _tl = NumberFormat('#,##0', 'tr_TR');

String tlBicim(int tutar) => '${_tl.format(tutar)} TL';

String tarihBicim(DateTime t) => '${t.day} ${_aylar[t.month - 1]} ${t.year}';

/// "12 Ekim 2026 08:30" gibi ISO metni okunur hale getirir.
String isoBicim(String? iso) {
  if (iso == null) return '—';
  final t = DateTime.tryParse(iso);
  if (t == null) return iso;
  final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  return '${tarihBicim(t)} $s';
}

/// Kalan gün etiketi; null → gösterilmez.
String? kalanEtiket(int? gun) {
  if (gun == null) return null;
  if (gun < 0) return 'Bitti';
  if (gun == 0) return 'Son gün';
  if (gun > 365) return 'Uzun süreli';
  return '$gun gün kaldı';
}

/// Banka rozeti: banka logosu yerine bankaya özgü renkte kısa ad.
class BankaRozeti extends StatelessWidget {
  final Banka banka;
  final bool buyuk;
  const BankaRozeti(this.banka, {super.key, this.buyuk = false});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: buyuk ? 10 : 8, vertical: buyuk ? 5 : 3),
      decoration: BoxDecoration(color: banka.renk, borderRadius: BorderRadius.circular(6)),
      child: Text(
        banka.kisa,
        maxLines: 1,
        style: (buyuk ? t.labelLarge : t.labelMedium)?.copyWith(
          color: banka.yazi,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Küçük, kenarlıklı bilgi etiketi.
class Etiket extends StatelessWidget {
  final String metin;
  final IconData? ikon;
  final Color? renk;
  final bool dolu;
  const Etiket(this.metin, {super.key, this.ikon, this.renk, this.dolu = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final r = renk ?? cs.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: dolu ? r.withValues(alpha: 0.14) : null,
        border: Border.all(color: r.withValues(alpha: dolu ? 0.0 : 0.45)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (ikon != null) ...[Icon(ikon, size: 13, color: r), const SizedBox(width: 3)],
          Text(
            metin,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: r, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Gruplara sabit ikonlar.
IconData grupIkonu(String grup) => switch (grup) {
      'Akaryakıt' => Icons.local_gas_station_outlined,
      'Market' => Icons.shopping_basket_outlined,
      'Giyim & Ayakkabı' => Icons.checkroom_outlined,
      'Elektronik' => Icons.devices_other_outlined,
      'E-ticaret' => Icons.shopping_cart_outlined,
      'Seyahat & Ulaşım' => Icons.flight_takeoff_outlined,
      'Yeme-İçme' => Icons.restaurant_outlined,
      'Kitap & Eğitim' => Icons.menu_book_outlined,
      'Sağlık & Kozmetik' => Icons.spa_outlined,
      'Eğlence & Kültür' => Icons.theater_comedy_outlined,
      'Otomotiv' => Icons.directions_car_outlined,
      'Ev & Mobilya' => Icons.chair_outlined,
      'Fatura & Dijital' => Icons.receipt_long_outlined,
      _ => Icons.local_offer_outlined,
    };

const _grupDosya = {
  'Akaryakıt': 'akaryakit',
  'Market': 'market',
  'Giyim & Ayakkabı': 'giyim',
  'Elektronik': 'elektronik',
  'E-ticaret': 'eticaret',
  'Seyahat & Ulaşım': 'seyahat',
  'Yeme-İçme': 'yemeicme',
  'Kitap & Eğitim': 'kitap',
  'Sağlık & Kozmetik': 'saglik',
  'Eğlence & Kültür': 'eglence',
  'Otomotiv': 'otomotiv',
  'Ev & Mobilya': 'ev',
  'Fatura & Dijital': 'fatura',
};

/// Gruba ait özgün 3B görsel (assets/gorsel; Gemini ile üretildi, marka/logo yok).
String grupDosyasi(String grup) => '${_grupDosya[grup] ?? 'diger'}.webp';
String grupGorseli(String grup) => 'assets/gorsel/${grupDosyasi(grup)}';

/// Bölüm başlığı + isteğe bağlı "Tümü" bağlantısı.
class BolumBasligi extends StatelessWidget {
  final String baslik;
  final String? alt;
  final VoidCallback? tumu;
  const BolumBasligi(this.baslik, {super.key, this.alt, this.tumu});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(baslik, style: t.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                if (alt != null) Text(alt!, style: t.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          if (tumu != null) TextButton(onPressed: tumu, child: const Text('Tümü')),
        ],
      ),
    );
  }
}

/// Yuvarlak profil resmi: fotoğraf varsa ağdan, yoksa baş harf; zümrüt halkalı.
class ProfilResmi extends StatelessWidget {
  final String? foto;
  final String bas;
  final double boyut;
  const ProfilResmi({super.key, this.foto, required this.bas, this.boyut = 44});

  @override
  Widget build(BuildContext context) {
    final yedek = Center(
      child: Text(bas, style: TextStyle(fontSize: boyut * 0.42, fontWeight: FontWeight.w800, color: const Color(0xFF0F1626))),
    );
    return Container(
      width: boyut,
      height: boyut,
      padding: EdgeInsets.all(boyut * 0.05),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: [Color(0xFF2DD4A7), Color(0xFFFFB547)]),
      ),
      child: ClipOval(
        child: Container(
          color: const Color(0xFFBFF3E4),
          child: foto == null
              ? yedek
              : Image.network(foto!, fit: BoxFit.cover, errorBuilder: (_, _, _) => yedek),
        ),
      ),
    );
  }
}
