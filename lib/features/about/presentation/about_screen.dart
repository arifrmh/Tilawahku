import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tentang aplikasi')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Center(
            child: Container(
              width: 76,
              height: 76,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0B2A5B),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.65),
                  width: 1.5,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/branding/tilawahku_icon.png',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Tilawahku',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Versi 1.0.0',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.68),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Pendamping membaca Al-Qur’an, menghafal, dan ibadah harian yang '
            'tenang serta nyaman digunakan setiap hari.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          const _AboutSectionTitle('Prinsip aplikasi'),
          const SizedBox(height: 8),
          _AboutCard(
            children: const [
              _AboutRow(
                icon: Icons.lock_outline_rounded,
                title: 'Privasi terjaga',
                detail:
                    'Progres bacaan, bookmark, hafalan, dan pengaturan '
                    'disimpan lokal di perangkat tanpa akun.',
              ),
              _AboutRow(
                icon: Icons.offline_pin_outlined,
                title: 'Siap dipakai offline',
                detail:
                    'Teks Al-Qur’an, terjemahan, doa harian, dan audio yang '
                    'diunduh tetap dapat diakses tanpa internet.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _AboutSectionTitle('Sumber dan rujukan'),
          const SizedBox(height: 8),
          _AboutCard(
            children: const [
              _AboutRow(
                icon: Icons.menu_book_outlined,
                title: 'Al-Qur’an dan terjemahan',
                detail:
                    'Teks Utsmani (Tanzil.net & AlQuran.cloud), terjemahan '
                    'Kementerian Agama RI, dan font Amiri Quran.',
              ),
              _AboutRow(
                icon: Icons.headphones_outlined,
                title: 'Audio murottal dan kajian',
                detail:
                    'Rekaman qari pilihan melalui Islamic Network, potret qari '
                    'berlisensi terbuka dari Wikimedia Commons, serta katalog '
                    'kajian podcast publik.',
              ),
              _AboutRow(
                icon: Icons.explore_outlined,
                title: 'Jadwal salat dan kiblat',
                detail:
                    'Perhitungan waktu salat dan kalender Hijriah dari '
                    'AlAdhan, data lokasi OpenStreetMap, serta arah kiblat '
                    'lokal.',
              ),
              _AboutRow(
                icon: Icons.auto_stories_outlined,
                title: 'Konten Islami',
                detail:
                    'Asmaul Husna, doa dan dzikir, kisah teladan, tokoh Islam, '
                    'serta panduan tajwid berdasarkan rujukan Al-Qur’an dan '
                    'hadis.',
              ),
            ],
          ),
          const SizedBox(height: 20),
          const _AboutSectionTitle('Lisensi'),
          const SizedBox(height: 8),
          _AboutCard(
            children: const [
              _AboutRow(
                icon: Icons.gavel_outlined,
                title: 'GNU GPL v3.0',
                detail:
                    'Kode sumber Tilawahku berlisensi GNU General Public '
                    'License v3.0. Konten pihak ketiga mengikuti lisensi '
                    'masing-masing sumber.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AboutSectionTitle extends StatelessWidget {
  const _AboutSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  const _AboutCard({required this.children});

  final List<_AboutRow> children;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                thickness: 1,
                indent: 62,
                color: colors.outlineVariant.withValues(alpha: 0.35),
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  const _AboutRow({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.74),
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
