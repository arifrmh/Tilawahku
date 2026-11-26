import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../domain/kajian_models.dart';
import 'kajian_controller.dart';

const List<double> _kajianPlaybackSpeeds = [0.75, 1.0, 1.25, 1.5, 2.0];

class KajianDetailScreen extends StatelessWidget {
  const KajianDetailScreen({
    super.key,
    required this.item,
    required this.controller,
  });

  final KajianItem item;
  final KajianController controller;

  Future<void> _copyText(
    BuildContext context,
    String text,
    String confirmation,
  ) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(confirmation)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final isFavorite = controller.isFavorite(item.id);
      final playback = controller.playbackState;
      final isCurrentItem = playback.item?.id == item.id;
      final isPlaying = isCurrentItem && playback.isPlaying;
      final isBuffering = isCurrentItem && playback.isBuffering;
      final savedRecord = controller.historyFor(item.id);

      final position = isCurrentItem
          ? playback.position
          : (savedRecord?.position ?? Duration.zero);
      final fallbackDuration = Duration(seconds: item.durationSeconds ?? 0);
      final duration = isCurrentItem && playback.duration > Duration.zero
          ? playback.duration
          : (savedRecord != null && savedRecord.durationMs > 0
                ? Duration(milliseconds: savedRecord.durationMs)
                : fallbackDuration);
      final maxMs = duration.inMilliseconds > 0
          ? duration.inMilliseconds.toDouble()
          : 1.0;
      final currentMs = position.inMilliseconds.toDouble().clamp(0.0, maxMs);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Detail kajian'),
          actions: [
            IconButton(
              tooltip: isFavorite ? 'Hapus dari tersimpan' : 'Simpan kajian',
              onPressed: () => controller.toggleFavorite(item.id),
              icon: Icon(
                isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Salin info kajian',
              onPressed: () {
                final shareText = [
                  item.title,
                  'Pemateri: ${item.speaker}',
                  'Sumber: ${item.sourceTitle}',
                  if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty)
                    'Tautan resmi: ${item.sourceUrl}',
                ].join('\n');
                _copyText(context, shareText, 'Info kajian disalin.');
              },
              icon: const Icon(Icons.copy_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _DetailHeaderCard(item: item),
            const SizedBox(height: 12),
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pemutar audio kajian',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: currentMs,
                      max: maxMs,
                      onChanged: isCurrentItem && duration > Duration.zero
                          ? (value) => controller.seek(
                              Duration(milliseconds: value.round()),
                            )
                          : null,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatKajianDuration(position),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                        Text(
                          duration > Duration.zero
                              ? formatKajianDuration(duration)
                              : item.formattedDuration,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          tooltip: 'Mundur 15 detik',
                          iconSize: 28,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: isCurrentItem
                              ? () => controller.seekRelative(
                                  const Duration(seconds: -15),
                                )
                              : null,
                          icon: const Icon(Icons.replay_10_rounded),
                        ),
                        const SizedBox(width: 16),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            minimumSize: const Size(148, 52),
                          ),
                          onPressed: isBuffering
                              ? null
                              : () => controller.playOrToggle(item),
                          icon: isBuffering
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                ),
                          label: Text(
                            isBuffering
                                ? 'Memuat...'
                                : (isPlaying ? 'Jeda' : 'Putar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          tooltip: 'Maju 15 detik',
                          iconSize: 28,
                          constraints: const BoxConstraints(
                            minWidth: 48,
                            minHeight: 48,
                          ),
                          onPressed: isCurrentItem
                              ? () => controller.seekRelative(
                                  const Duration(seconds: 15),
                                )
                              : null,
                          icon: const Icon(Icons.forward_10_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Kecepatan putar',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final speed in _kajianPlaybackSpeeds)
                          ChoiceChip(
                            label: Text('${speed}x'),
                            selected: (playback.speed - speed).abs() < 0.01,
                            onSelected: (_) => controller.setSpeed(speed),
                          ),
                      ],
                    ),
                    if (isCurrentItem && playback.errorMessage != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          playback.errorMessage!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Text(
                      'Audio kajian diputar secara streaming dari penerbit RSS dan memerlukan koneksi internet aktif. Pemutaran murottal akan dijeda otomatis agar tidak bertabrakan.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (item.description.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan kajian',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(item.description),
                    ],
                  ),
                ),
              ),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: 20,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Sumber dan lisensi',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _AttributionRow(label: 'Penerbit', value: item.sourceTitle),
                    _AttributionRow(label: 'Pemateri', value: item.speaker),
                    _AttributionRow(label: 'Lisensi', value: item.licenseNote),
                    _AttributionRow(label: 'Feed RSS', value: item.feedUrl),
                    if (item.sourceUrl != null && item.sourceUrl!.isNotEmpty)
                      _AttributionRow(
                        label: 'Tautan resmi',
                        value: item.sourceUrl!,
                      ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _copyText(
                            context,
                            item.sourceUrl ?? item.feedUrl,
                            'Tautan sumber resmi disalin.',
                          ),
                          icon: const Icon(Icons.link_rounded, size: 18),
                          label: const Text('Salin tautan resmi'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Konten berasal langsung dari feed RSS podcast terbuka yang Anda tambahkan. Anda dapat menonaktifkan atau menghapus sumber ini kapan saja dari menu Kelola sumber.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _DetailHeaderCard extends StatelessWidget {
  const _DetailHeaderCard({required this.item});

  final KajianItem item;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.navy,
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              item.category.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppColors.parchment,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.speaker,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.gold,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            [
              item.sourceTitle,
              item.formattedDuration,
              if (item.publishedAt != null && item.publishedAt!.isNotEmpty)
                item.publishedAt!,
            ].join(' · '),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.parchment.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    ),
  );
}

class _AttributionRow extends StatelessWidget {
  const _AttributionRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    ),
  );
}
