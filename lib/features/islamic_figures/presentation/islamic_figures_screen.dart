import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../data/islamic_figures_repository.dart';
import '../domain/islamic_figures_models.dart';
import 'islamic_figures_controller.dart';

class IslamicFiguresScreen extends StatefulWidget {
  const IslamicFiguresScreen({
    super.key,
    required this.preferences,
    this.repository,
  });

  final AppPreferences preferences;
  final IslamicFiguresRepository? repository;

  @override
  State<IslamicFiguresScreen> createState() => _IslamicFiguresScreenState();
}

class _IslamicFiguresScreenState extends State<IslamicFiguresScreen> {
  late final IslamicFiguresController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = IslamicFiguresController(
      repository:
          widget.repository ??
          IslamicFiguresRepository(preferences: widget.preferences),
    );
    _controller.load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openDetail(IslamicFigure figure) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => IslamicFigureDetailScreen(
          figure: figure,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final visible = _controller.visibleItems;
      return Scaffold(
        appBar: AppBar(
          title: const Text('Tokoh Islam'),
          actions: [
            IconButton(
              tooltip: _controller.favoritesOnly
                  ? 'Tampilkan semua tokoh'
                  : 'Tampilkan tokoh tersimpan',
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

  Widget _buildBody(BuildContext context, List<IslamicFigure> visible) {
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
              const Text('Data tokoh Islam gagal dimuat.'),
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
              hintText: 'Cari nama, julukan, atau era tokoh...',
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
                child: FilterChip(
                  label: const Text('Semua'),
                  selected: _controller.selectedCategory == null,
                  onSelected: (_) => _controller.setCategory(null),
                ),
              ),
              for (final category in FigureCategory.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
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
                              ? 'Belum ada tokoh tersimpan.'
                              : 'Tidak ada tokoh yang cocok dengan pencarian.',
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
                    final figure = visible[index];
                    return _FigureCard(
                      figure: figure,
                      isFavorite: _controller.isFavorite(figure.id),
                      onTap: () => _openDetail(figure),
                      onToggleFavorite: () =>
                          _controller.toggleFavorite(figure.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _FigureCard extends StatelessWidget {
  const _FigureCard({
    required this.figure,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final IslamicFigure figure;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.navy,
                    foregroundColor: AppColors.gold,
                    child: Text(
                      figure.monogram,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          figure.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          figure.arabicName,
                          textDirection: TextDirection.rtl,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontFamily: 'AmiriQuran',
                            fontSize: 18,
                            height: 1.5,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Hapus dari tersimpan'
                        : 'Simpan tokoh',
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: isFavorite ? colors.primary : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _MetaPill(label: figure.category.label),
                  _MetaPill(label: figure.eraLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                figure.epithet,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                figure.summary,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
    );
  }
}

class IslamicFigureDetailScreen extends StatefulWidget {
  const IslamicFigureDetailScreen({
    super.key,
    required this.figure,
    required this.controller,
  });

  final IslamicFigure figure;
  final IslamicFiguresController controller;

  @override
  State<IslamicFigureDetailScreen> createState() =>
      _IslamicFigureDetailScreenState();
}

class _IslamicFigureDetailScreenState extends State<IslamicFigureDetailScreen> {
  double _textScale = 1.0;

  void _adjustScale(double delta) {
    setState(() {
      _textScale = (_textScale + delta).clamp(0.85, 1.45);
    });
  }

  Future<void> _copySummary() async {
    await Clipboard.setData(
      ClipboardData(text: widget.controller.formatCopyText(widget.figure)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Ringkasan biografi disalin.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final figure = widget.figure;
    final theme = Theme.of(context);
    final bodyStyle = theme.textTheme.bodyMedium?.copyWith(
      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) * _textScale,
      height: 1.65,
    );

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final isFavorite = widget.controller.isFavorite(figure.id);
        return Scaffold(
          appBar: AppBar(
            title: Text(figure.name),
            actions: [
              IconButton(
                tooltip: 'Perkecil teks',
                onPressed: _textScale <= 0.85
                    ? null
                    : () => _adjustScale(-0.1),
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
                tooltip: isFavorite ? 'Hapus dari tersimpan' : 'Simpan tokoh',
                onPressed: () => widget.controller.toggleFavorite(figure.id),
                icon: Icon(
                  isFavorite
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                ),
              ),
              IconButton(
                tooltip: 'Salin ringkasan',
                onPressed: _copySummary,
                icon: const Icon(Icons.copy_rounded),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                color: AppColors.navy,
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        figure.category.label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Text(
                          figure.arabicName,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: 28,
                            height: 1.6,
                            color: AppColors.parchment,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        figure.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppColors.parchment,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        figure.epithet,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.parchment,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        figure.eraLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                      if (figure.dateNote case final note?
                          when note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.parchment.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ringkasan',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(figure.summary, style: bodyStyle),
                    ],
                  ),
                ),
              ),
              for (final section in figure.biographySections)
                Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          section.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(section.body, style: bodyStyle),
                      ],
                    ),
                  ),
                ),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Keteladanan utama',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final lesson in figure.keyLessons)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(lesson, style: bodyStyle)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rujukan sejarah',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final reference in figure.references)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(
                                child: Text(
                                  reference,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                            ],
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
}
