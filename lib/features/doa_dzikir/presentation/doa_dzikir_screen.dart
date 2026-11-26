import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/preferences/app_preferences.dart';
import '../data/doa_dzikir_repository.dart';
import '../domain/doa_dzikir_models.dart';
import 'doa_dzikir_controller.dart';

class DoaDzikirScreen extends StatefulWidget {
  const DoaDzikirScreen({
    super.key,
    required this.preferences,
    this.repository,
  });

  final AppPreferences preferences;
  final DoaDzikirRepository? repository;

  @override
  State<DoaDzikirScreen> createState() => _DoaDzikirScreenState();
}

class _DoaDzikirScreenState extends State<DoaDzikirScreen> {
  late final DoaDzikirController _controller;
  final TextEditingController _searchController = TextEditingController();
  double _textScale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = DoaDzikirController(
      repository:
          widget.repository ??
          DoaDzikirRepository(preferences: widget.preferences),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _adjustScale(double delta) {
    setState(() {
      _textScale = (_textScale + delta).clamp(0.85, 1.45);
    });
  }

  Future<void> _copyEntry(DoaDzikirEntry entry) async {
    await Clipboard.setData(
      ClipboardData(text: _controller.formatCopyText(entry)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teks doa/dzikir dan rujukan disalin.')),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final visible = _controller.visibleItems;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Doa dan dzikir'),
          actions: [
            IconButton(
              tooltip: 'Perkecil teks',
              onPressed: _textScale <= 0.85 ? null : () => _adjustScale(-0.1),
              icon: const Text(
                'A-',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: 'Perbesar teks',
              onPressed: _textScale >= 1.45 ? null : () => _adjustScale(0.1),
              icon: const Text(
                'A+',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            IconButton(
              tooltip: _controller.favoritesOnly
                  ? 'Tampilkan semua bacaan'
                  : 'Tampilkan bacaan tersimpan',
              onPressed: _controller.toggleFavoritesOnly,
              icon: Icon(
                _controller.favoritesOnly
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ],
        ),
        body: _buildBody(context, visible),
      );
    },
  );

  Widget _buildBody(BuildContext context, List<DoaDzikirEntry> visible) {
    if (_controller.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_controller.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48),
              const SizedBox(height: 12),
              const Text('Katalog doa dan dzikir gagal dimuat.'),
              const SizedBox(height: 8),
              Text('${_controller.error}', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _controller.load,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: _controller.setQuery,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Cari doa, dzikir, arti, atau rujukan...',
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
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('Semua'),
                  selected: _controller.selectedCategory == null,
                  onSelected: (_) => _controller.setCategory(null),
                ),
              ),
              for (final category in DoaDzikirCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: _controller.selectedCategory == category,
                    onSelected: (_) => _controller.setCategory(
                      _controller.selectedCategory == category
                          ? null
                          : category,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: visible.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _controller.favoritesOnly
                              ? Icons.bookmark_border_rounded
                              : Icons.search_off_rounded,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _controller.favoritesOnly
                              ? 'Belum ada bacaan tersimpan.'
                              : 'Tidak ada bacaan yang cocok dengan pencarian.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  itemCount: visible.length,
                  itemBuilder: (context, index) {
                    final entry = visible[index];
                    return _DoaDzikirCard(
                      entry: entry,
                      textScale: _textScale,
                      isFavorite: _controller.isFavorite(entry.id),
                      currentReadCount: _controller.readCount(entry.id),
                      onToggleFavorite: () =>
                          _controller.toggleFavorite(entry.id),
                      onCopy: () => _copyEntry(entry),
                      onTapCount: entry.repeatCount > 1
                          ? () => _controller.incrementReadCount(entry)
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _DoaDzikirCard extends StatelessWidget {
  const _DoaDzikirCard({
    required this.entry,
    required this.textScale,
    required this.isFavorite,
    required this.currentReadCount,
    required this.onToggleFavorite,
    required this.onCopy,
    this.onTapCount,
  });

  final DoaDzikirEntry entry;
  final double textScale;
  final bool isFavorite;
  final int currentReadCount;
  final VoidCallback onToggleFavorite;
  final VoidCallback onCopy;
  final VoidCallback? onTapCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final bodySize = (theme.textTheme.bodyMedium?.fontSize ?? 14) * textScale;
    final done = entry.repeatCount > 1 && currentReadCount >= entry.repeatCount;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.category.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (entry.repeatCount > 1)
                  ActionChip(
                    key: ValueKey('doa-repeat-${entry.id}'),
                    avatar: Icon(
                      done
                          ? Icons.check_circle_rounded
                          : Icons.touch_app_outlined,
                      size: 16,
                    ),
                    label: Text(
                      currentReadCount == 0
                          ? 'Dibaca ${entry.repeatCount}x'
                          : '$currentReadCount/${entry.repeatCount}',
                    ),
                    visualDensity: VisualDensity.compact,
                    onPressed: onTapCount,
                  ),
                const Spacer(),
                IconButton(
                  tooltip: isFavorite ? 'Hapus dari tersimpan' : 'Simpan bacaan',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFavorite ? colors.primary : null,
                  ),
                ),
                IconButton(
                  tooltip: 'Salin bacaan',
                  onPressed: onCopy,
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              entry.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'AmiriQuran',
                fontSize: 24 * textScale,
                height: 1.85,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              entry.transliteration,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: bodySize,
                height: 1.55,
                fontStyle: FontStyle.italic,
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              entry.translationId,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: bodySize,
                height: 1.6,
              ),
            ),
            if (entry.notes case final note? when note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.menu_book_outlined,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    entry.sourceRef,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
