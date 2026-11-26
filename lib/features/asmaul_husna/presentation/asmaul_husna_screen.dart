import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../reading/data/reading_repository.dart';
import '../../reading/presentation/reading_screen.dart';
import '../data/asmaul_husna_repository.dart';
import '../domain/asmaul_husna_models.dart';
import 'asmaul_husna_controller.dart';

class AsmaulHusnaScreen extends StatefulWidget {
  const AsmaulHusnaScreen({
    super.key,
    required this.preferences,
    required this.readingRepository,
    this.controller,
  });

  final AppPreferences preferences;
  final ReadingRepository readingRepository;

  /// Hanya untuk pengujian.
  final AsmaulHusnaController? controller;

  @override
  State<AsmaulHusnaScreen> createState() => _AsmaulHusnaScreenState();
}

class _AsmaulHusnaScreenState extends State<AsmaulHusnaScreen> {
  late final AsmaulHusnaController _controller;
  late final bool _ownsController;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        AsmaulHusnaController(
          repository: AsmaulHusnaRepository(preferences: widget.preferences),
        );
    _controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleFavorite(AsmaulHusnaEntry entry) async {
    final added = await _controller.toggleFavorite(entry.number);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${entry.transliteration} disimpan ke favorit.'
                : '${entry.transliteration} dihapus dari favorit.',
          ),
        ),
      );
  }

  Future<void> _copyEntry(AsmaulHusnaEntry entry) async {
    await Clipboard.setData(ClipboardData(text: entry.copyText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${entry.transliteration} disalin.')),
      );
  }

  Future<void> _openAyahRef(AsmaulHusnaAyahRef ref) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => ReadingScreen(
          repository: widget.readingRepository,
          preferences: widget.preferences,
          surahNumber: ref.surah,
          startingAyah: ref.ayah,
        ),
      ),
    );
  }

  Future<void> _openDetail(AsmaulHusnaEntry entry) async {
    final initialIndex = _controller.allEntries.indexWhere(
      (item) => item.number == entry.number,
    );
    if (initialIndex < 0) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _AsmaulHusnaDetailSheet(
        controller: _controller,
        initialIndex: initialIndex,
        onCopy: _copyEntry,
        onToggleFavorite: _toggleFavorite,
        onOpenAyahRef: (ref) {
          Navigator.of(context).pop();
          _openAyahRef(ref);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => Scaffold(
      appBar: AppBar(
        title: const Text('Asmaul Husna'),
        actions: [
          IconButton(
            tooltip: _controller.favoritesOnly
                ? 'Tampilkan semua nama'
                : 'Filter favorit',
            onPressed: _controller.state == AsmaulHusnaLoadState.ready
                ? _controller.toggleFavoritesOnly
                : null,
            icon: Icon(
              _controller.favoritesOnly
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
            ),
          ),
        ],
      ),
      body: switch (_controller.state) {
        AsmaulHusnaLoadState.loading => const Center(
          child: CircularProgressIndicator(),
        ),
        AsmaulHusnaLoadState.failed => _StatusMessage(
          icon: Icons.error_outline_rounded,
          title: 'Asmaul Husna tidak dapat dimuat',
          detail: _controller.errorMessage ?? 'Terjadi kesalahan saat membaca data.',
          actionLabel: 'Coba lagi',
          onAction: _controller.load,
        ),
        AsmaulHusnaLoadState.ready => _buildReadyBody(context),
      },
    ),
  );

  Widget _buildReadyBody(BuildContext context) {
    final entries = _controller.visibleEntries;
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.72);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onChanged: _controller.setQuery,
            decoration: InputDecoration(
              hintText: 'Cari nomor, nama, atau arti',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian',
                      onPressed: () {
                        _searchController.clear();
                        _controller.setQuery('');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              isDense: true,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Row(
            children: [
              Text(
                _controller.favoritesOnly || _controller.query.trim().isNotEmpty
                    ? 'Menampilkan ${entries.length} dari ${_controller.allEntries.length} nama'
                    : '${_controller.allEntries.length} nama Allah (tersedia offline)',
                style: theme.textTheme.bodySmall?.copyWith(color: muted),
              ),
              const Spacer(),
              if (_controller.favorites.isNotEmpty)
                Text(
                  '${_controller.favorites.length} favorit',
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
            ],
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? _StatusMessage(
                  icon: _controller.favoritesOnly
                      ? Icons.bookmark_border_rounded
                      : Icons.search_off_rounded,
                  title: _controller.favoritesOnly
                      ? 'Belum ada Asmaul Husna favorit'
                      : 'Nama tidak ditemukan',
                  detail: _controller.favoritesOnly
                      ? 'Ketuk ikon penanda pada salah satu nama untuk menyimpannya di sini.'
                      : 'Tidak ada hasil untuk "${_controller.query.trim()}".',
                  actionLabel: 'Tampilkan semua',
                  onAction: () {
                    _searchController.clear();
                    _controller.clearFilters();
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _AsmaulHusnaTile(
                      entry: entry,
                      isFavorite: _controller.isFavorite(entry.number),
                      onTap: () => _openDetail(entry),
                      onToggleFavorite: () => _toggleFavorite(entry),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _AsmaulHusnaTile extends StatelessWidget {
  const _AsmaulHusnaTile({
    required this.entry,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final AsmaulHusnaEntry entry;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final muted = colorScheme.onSurface.withValues(alpha: 0.74);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${entry.number}',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.transliteration,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      entry.meaningId,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                entry.arabic,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  fontFamily: 'AmiriQuran',
                  fontSize: 22,
                  height: 1.6,
                ),
              ),
              IconButton(
                tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan favorit',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isFavorite ? AppColors.gold : muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsmaulHusnaDetailSheet extends StatefulWidget {
  const _AsmaulHusnaDetailSheet({
    required this.controller,
    required this.initialIndex,
    required this.onCopy,
    required this.onToggleFavorite,
    required this.onOpenAyahRef,
  });

  final AsmaulHusnaController controller;
  final int initialIndex;
  final Future<void> Function(AsmaulHusnaEntry) onCopy;
  final Future<void> Function(AsmaulHusnaEntry) onToggleFavorite;
  final ValueChanged<AsmaulHusnaAyahRef> onOpenAyahRef;

  @override
  State<_AsmaulHusnaDetailSheet> createState() =>
      _AsmaulHusnaDetailSheetState();
}

class _AsmaulHusnaDetailSheetState extends State<_AsmaulHusnaDetailSheet> {
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final entries = widget.controller.allEntries;
      final entry = entries[_index];
      final isFavorite = widget.controller.isFavorite(entry.number);
      final theme = Theme.of(context);
      final muted = theme.colorScheme.onSurface.withValues(alpha: 0.74);

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: AppColors.navy,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'Nama ke-${entry.number} dari ${entries.length}',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.arabic,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 34,
                        height: 1.7,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      entry.transliteration,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.parchment,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.meaningId,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.parchment.withValues(alpha: 0.86),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Makna dan penghayatan',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.descriptionId,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
            ),
            if (entry.quranRefs.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Rujukan ayat Al-Qur’an',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final ref in entry.quranRefs)
                    ActionChip(
                      avatar: const Icon(Icons.menu_book_outlined, size: 18),
                      label: Text(ref.label),
                      onPressed: () => widget.onOpenAyahRef(ref),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => widget.onCopy(entry),
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Salin'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => widget.onToggleFavorite(entry),
                    icon: Icon(
                      isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      size: 18,
                    ),
                    label: Text(isFavorite ? 'Tersimpan' : 'Favorit'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _index > 0
                        ? () => setState(() => _index--)
                        : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Sebelumnya'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _index < entries.length - 1
                        ? () => setState(() => _index++)
                        : null,
                    iconAlignment: IconAlignment.end,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Berikutnya'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Urutan populer riwayat At-Tirmidzi (99 nama). Rujukan ayat '
              'terhubung ke teks Al-Qur’an lokal.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    },
  );
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({
    required this.icon,
    required this.title,
    required this.detail,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.74);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: muted),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              detail,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }
}
