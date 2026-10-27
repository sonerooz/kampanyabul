/// Türkçe arama normu — `uygulama_verisi.py` içindeki `norm()` ile aynı kurallar:
/// İ→i, I→ı, küçük harf, aksan katlama (ı/i, ş/s, ğ/g, ü/u, ö/o, ç/c),
/// harf/rakam/% dışındaki her şey boşluk.
library;

const Map<String, String> _katla = {
  'ı': 'i',
  'ş': 's',
  'ğ': 'g',
  'ü': 'u',
  'ö': 'o',
  'ç': 'c',
  'â': 'a',
  'î': 'i',
  'û': 'u',
  'é': 'e',
  'ë': 'e',
  'á': 'a',
};

final RegExp _harfDisi = RegExp(r'[^a-z0-9%]+');

/// Türkçe kurallarla küçük harfe çevirir (İ→i, I→ı).
String turkceKucuk(String s) =>
    s.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase().replaceAll('i̇', 'i');

String norm(String s) {
  final k = turkceKucuk(s).replaceAll('&', ' ve ').replaceAll('’', "'");
  final b = StringBuffer();
  for (final r in k.runes) {
    final c = String.fromCharCode(r);
    b.write(_katla[c] ?? c);
  }
  return b.toString().replaceAll(_harfDisi, ' ').trim();
}

/// Sorguyu kelimelere böler (normalize edilmiş, boşsuz).
List<String> sorguKelimeleri(String sorgu) =>
    norm(sorgu).split(' ').where((w) => w.isNotEmpty).toList();
