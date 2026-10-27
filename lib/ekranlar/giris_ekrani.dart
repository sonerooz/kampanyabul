import 'package:flutter/material.dart';

import '../durum.dart';
import '../tema.dart';
import 'profil_ekrani.dart';

/// İlk açılışta bir kez: kapak görseli, kısa vaat, Google / Facebook / misafir.
class GirisEkrani extends StatelessWidget {
  const GirisEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final d = UygulamaKapsami.of(context);
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: ShaderMask(
              shaderCallback: (r) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.transparent],
                stops: [0.55, 1],
              ).createShader(r),
              blendMode: BlendMode.dstIn,
              child: Image.asset('assets/gorsel/kapak.webp', fit: BoxFit.cover, width: double.infinity, height: MediaQuery.sizeOf(context).height * 0.62),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(onPressed: () => d.girisGoruldu = true, child: const Text('Atla')),
                  ),
                  const Spacer(),
                  Text('KampanyaBul', style: t.titleMedium?.copyWith(color: R.zumrut, fontWeight: FontWeight.w800, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  Text('Kartına uyan fırsatı\nkaçırma.', style: t.displaySmall?.copyWith(fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1)),
                  const SizedBox(height: 12),
                  Text(
                    '20\'ye yakın banka ve cüzdanın kampanyaları tek yerde. Kartını ekle, sana uyanları ve bitmek üzere olanları biz gösterelim.',
                    style: t.bodyLarge?.copyWith(color: R.soluk, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  SosyalGirisDugmeleri(sonra: () => d.girisGoruldu = true),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => d.girisGoruldu = true,
                      style: TextButton.styleFrom(foregroundColor: R.yazi),
                      child: const Text('Giriş yapmadan devam et'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
