import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../data/kajian_audio_playback.dart';
import '../data/kajian_repository.dart';
import '../domain/kajian_models.dart';
import 'kajian_controller.dart';
import 'kajian_detail_screen.dart';

class KajianListScreen extends StatefulWidget {
  const KajianListScreen({
    super.key,
    this.preferences,
    this.repository,
    this.playback,
  });

  final AppPreferences? preferences;
  final KajianRepository? repository;
  final KajianAudioPlayback? playback;

  @override
  State<KajianListScreen> createState() => _KajianListScreenState();
}

class _KajianListScreenState extends State<KajianListScreen> {
  late final KajianController _controller;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _controller = KajianController(
      repository:
          widget.repository ??
          KajianRepository(preferences: widget.preferences),
      playback: widget.playback,
    );
    _searchController = TextEditingController();
    _controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _openDetail(KajianItem item) {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => KajianDetailScreen(item: item, controller: _controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final colors = Theme.of(context).colorScheme;
        final showTabs = _controller.catalog.items.isNotEmpty;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kajian dan ceramah'),
            actions: [
              IconButton(
                tooltip: 'Perbarui katalog kajian',
                onPressed:
                    _controller.isRefreshing ||
                        _controller.catalog.sources.isEmpty
                    ? null
                    : () => _controller.load(forceRefresh: true),
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            bottom: !showTabs
                ? null
                : PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ),
                        child: TabBar(
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          indicator: BoxDecoration(
                            color: colors.primary,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          labelColor: colors.onPrimary,
                          unselectedLabelColor: colors.onSurface.withValues(
                            alpha: 0.72,
                          ),
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          tabs: const [
                            Tab(text: 'Semua'),
                            Tab(text: 'Tersimpan'),
                            Tab(text: 'Riwayat'),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          body: _buildBody(context),
          bottomNavigationBar: _controller.playbackState.item == null
              ? null
              : _MiniKajianPlayerBar(
                  state: _controller.playbackState,
                  onTogglePlay: () =>
                      _controller.playOrToggle(_controller.playbackState.item!),
                  onOpenDetail: () =>
                      _openDetail(_controller.playbackState.item!),
                ),
        );
      },
    ),
  );

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.catalog.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              'Memuat katalog kajian...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }
    if (_controller.catalog.sources.isEmpty) {
      return _EmptySourcesState(
        onRestoreDefaults: _controller.restoreDefaultSources,
      );
    }
    if (_controller.catalog.items.isEmpty &&
        _controller.catalog.warnings.isNotEmpty) {
      return _OfflineKajianState(
        isRefreshing: _controller.isRefreshing,
        onRetry: () => _controller.load(forceRefresh: true),
      );
    }

    return Column(
      children: [
        if (_controller.catalog.warnings.isNotEmpty)
          _CatalogStatusBanner(
            fromCache: _controller.catalog.fromCache,
            warnings: _controller.catalog.warnings,
            isRefreshing: _controller.isRefreshing,
            onRefresh: () => _controller.load(forceRefresh: true),
          ),
        Expanded(
          child: TabBarView(
            children: [
              _CatalogTab(
                items: _controller.filteredItems,
                searchController: _searchController,
                controller: _controller,
                emptyMessage:
                    'Tidak ada kajian yang cocok dengan filter saat ini.',
                onOpenDetail: _openDetail,
              ),
              _CatalogTab(
                items: _controller.savedItems,
                searchController: _searchController,
                controller: _controller,
                emptyMessage:
                    'Belum ada kajian tersimpan. Tekan ikon bookmark pada kajian untuk menyimpannya.',
                onOpenDetail: _openDetail,
              ),
              _HistoryTab(
                controller: _controller,
                onOpenDetail: _openDetail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OfflineKajianState extends StatelessWidget {
  const _OfflineKajianState({
    required this.isRefreshing,
    required this.onRetry,
  });

  final bool isRefreshing;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 30,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Katalog kajian memerlukan koneksi internet',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Hubungkan perangkat ke internet untuk memuat daftar kajian dan memutar audio ceramah.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: isRefreshing ? null : onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isRefreshing ? 'Memuat...' : 'Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySourcesState extends StatelessWidget {
  const _EmptySourcesState({required this.onRestoreDefaults});

  final VoidCallback onRestoreDefaults;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.podcasts_rounded,
                size: 32,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Katalog kajian belum dimuat',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Muat katalog kajian bawaan agar langsung siap diputar.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRestoreDefaults,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Muat katalog kajian'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogStatusBanner extends StatelessWidget {
  const _CatalogStatusBanner({
    required this.fromCache,
    required this.warnings,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final bool fromCache;
  final List<String> warnings;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasWarning = warnings.isNotEmpty;
    final message = hasWarning
        ? warnings.first
        : 'Menampilkan katalog dari cache lokal. Pemutaran audio streaming memerlukan internet.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: hasWarning
          ? theme.colorScheme.errorContainer
          : theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(
            hasWarning
                ? Icons.cloud_off_rounded
                : Icons.offline_pin_outlined,
            size: 18,
            color: hasWarning
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: hasWarning
                    ? theme.colorScheme.onErrorContainer
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          TextButton(
            onPressed: isRefreshing ? null : onRefresh,
            child: Text(isRefreshing ? 'Memuat...' : 'Segarkan'),
          ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.items,
    required this.searchController,
    required this.controller,
    required this.emptyMessage,
    required this.onOpenDetail,
  });

  final List<KajianItem> items;
  final TextEditingController searchController;
  final KajianController controller;
  final String emptyMessage;
  final ValueChanged<KajianItem> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final speakers = controller.speakers;

    return RefreshIndicator(
      onRefresh: () => controller.load(forceRefresh: true),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          TextField(
            controller: searchController,
            onChanged: controller.setQuery,
            decoration: InputDecoration(
              hintText: 'Cari judul kajian, topik, atau pemateri',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: controller.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        searchController.clear();
                        controller.setQuery('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Semua'),
                    selected: controller.selectedCategory == null,
                    onSelected: (_) => controller.setCategory(null),
                  ),
                ),
                for (final category in KajianCategory.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category.label),
                      selected: controller.selectedCategory == category,
                      onSelected: (_) => controller.setCategory(
                        controller.selectedCategory == category
                            ? null
                            : category,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (speakers.length > 1) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: const Text('Semua pemateri'),
                      selected: controller.selectedSpeaker == null,
                      onSelected: (_) => controller.setSpeaker(null),
                    ),
                  ),
                  for (final speaker in speakers)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(speaker),
                        selected: controller.selectedSpeaker == speaker,
                        onSelected: (_) => controller.setSpeaker(
                          controller.selectedSpeaker == speaker
                              ? null
                              : speaker,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (items.isEmpty)
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(emptyMessage, textAlign: TextAlign.center),
              ),
            )
          else
            for (final item in items)
              _KajianItemCard(
                item: item,
                isFavorite: controller.isFavorite(item.id),
                isPlaying:
                    controller.playbackState.item?.id == item.id &&
                    controller.playbackState.isPlaying,
                onTap: () => onOpenDetail(item),
                onToggleFavorite: () => controller.toggleFavorite(item.id),
                onPlayToggle: () => controller.playOrToggle(item),
              ),
        ],
      ),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.controller,
    required this.onOpenDetail,
  });

  final KajianController controller;
  final ValueChanged<KajianItem> onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final entries = controller.historyEntries;
    if (entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: const [
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Belum ada riwayat pemutaran kajian.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final item = entry.item;
        final record = entry.record;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: InkWell(
            onTap: () => onOpenDetail(item),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.speaker} · ${item.sourceTitle}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: record.progressFraction,
                    minHeight: 6,
                    semanticsLabel: 'Progres putar kajian',
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Terakhir di ${formatKajianDuration(record.position)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _KajianItemCard extends StatelessWidget {
  const _KajianItemCard({
    required this.item,
    required this.isFavorite,
    required this.isPlaying,
    required this.onTap,
    required this.onToggleFavorite,
    required this.onPlayToggle,
  });

  final KajianItem item;
  final bool isFavorite;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final VoidCallback onPlayToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: isPlaying
          ? colors.primary.withValues(alpha: 0.05)
          : colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPlaying
              ? AppColors.gold
              : colors.outlineVariant.withValues(alpha: 0.45),
          width: isPlaying ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton.filledTonal(
                tooltip: isPlaying ? 'Jeda kajian' : 'Putar kajian',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onPlayToggle,
                icon: Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.speaker,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.category.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '${item.formattedDuration} · ${item.sourceTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.72),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Hapus dari tersimpan' : 'Simpan kajian',
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniKajianPlayerBar extends StatelessWidget {
  const _MiniKajianPlayerBar({
    required this.state,
    required this.onTogglePlay,
    required this.onOpenDetail,
  });

  final KajianPlaybackState state;
  final VoidCallback onTogglePlay;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final item = state.item!;
    return Material(
      color: AppColors.navy,
      elevation: 4,
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: onOpenDetail,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.podcasts_rounded, color: AppColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '${item.speaker} · ${formatKajianDuration(state.position)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.parchment.withValues(alpha: 0.82),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: state.isPlaying ? 'Jeda' : 'Putar',
                  color: AppColors.gold,
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: state.isBuffering ? null : onTogglePlay,
                  icon: Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
