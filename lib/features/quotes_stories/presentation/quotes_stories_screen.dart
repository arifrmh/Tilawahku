import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../data/quotes_stories_repository.dart';
import '../domain/quotes_stories_models.dart';
import 'quotes_stories_controller.dart';

class QuotesStoriesScreen extends StatefulWidget {
  const QuotesStoriesScreen({
    super.key,
    required this.preferences,
    this.controller,
  });

  final AppPreferences preferences;

  /// Hanya untuk pengujian.
  final QuotesStoriesController? controller;

  @override
  State<QuotesStoriesScreen> createState() => _QuotesStoriesScreenState();
}

class _QuotesStoriesScreenState extends State<QuotesStoriesScreen> {
  late final QuotesStoriesController _controller;
  late final bool _ownsController;
  final TextEditingController _quoteSearchController = TextEditingController();
  final TextEditingController _storySearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        QuotesStoriesController(
          repository: QuotesStoriesRepository(preferences: widget.preferences),
        );
    _controller.load();
  }

  @override
  void dispose() {
    _quoteSearchController.dispose();
    _storySearchController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _copyText(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleQuoteFavorite(IslamicQuote quote) async {
    final added = await _controller.toggleQuoteFavorite(quote.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? 'Kutipan disimpan ke favorit.'
                : 'Kutipan dihapus dari favorit.',
          ),
        ),
      );
  }

  Future<void> _toggleStoryFavorite(IslamicStory story) async {
    final added = await _controller.toggleStoryFavorite(story.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${story.title} disimpan ke favorit.'
                : '${story.title} dihapus dari favorit.',
          ),
        ),
      );
  }

  Future<void> _openStory(IslamicStory story) => Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (_) => StoryDetailScreen(
        story: story,
        controller: _controller,
        onCopy: () => _copyText(
          story.copyText,
          'Ringkasan kisah beserta rujukan disalin.',
        ),
        onToggleFavorite: () => _toggleStoryFavorite(story),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) => DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quotes dan Kisah'),
          actions: [
            IconButton(
              tooltip: _controller.favoritesOnly
                  ? 'Tampilkan semua konten'
                  : 'Filter favorit',
              onPressed: _controller.state == QuotesStoriesLoadState.ready
                  ? _controller.toggleFavoritesOnly
                  : null,
              icon: Icon(
                _controller.favoritesOnly
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Quotes'),
              Tab(text: 'Kisah'),
            ],
          ),
        ),
        body: switch (_controller.state) {
          QuotesStoriesLoadState.loading => const Center(
            child: CircularProgressIndicator(),
          ),
          QuotesStoriesLoadState.failed => _EmptyStateView(
            icon: Icons.error_outline_rounded,
            title: 'Konten tidak dapat dimuat',
            detail:
                _controller.errorMessage ??
                'Terjadi kesalahan saat membaca data lokal.',
            actionLabel: 'Coba lagi',
            onAction: _controller.load,
          ),
          QuotesStoriesLoadState.ready => TabBarView(
            children: [
              _buildQuotesTab(context),
              _buildStoriesTab(context),
            ],
          ),
        },
      ),
    ),
  );

  Widget _buildQuotesTab(BuildContext context) {
    final quotes = _controller.visibleQuotes;
    final showDailyCard =
        !_controller.favoritesOnly &&
        _controller.selectedQuoteCategory == null &&
        _controller.quoteQuery.trim().isEmpty &&
        _controller.todayQuote != null;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _quoteSearchController,
            textInputAction: TextInputAction.search,
            onChanged: _controller.setQuoteQuery,
            decoration: InputDecoration(
              hintText: 'Cari kutipan, tokoh, atau sumber',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.quoteQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian kutipan',
                      onPressed: () {
                        _quoteSearchController.clear();
                        _controller.setQuoteQuery('');
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
        _CategoryFilterBar(
          categories: _controller.quoteCategories,
          selected: _controller.selectedQuoteCategory,
          onSelected: _controller.selectQuoteCategory,
        ),
        Expanded(
          child: quotes.isEmpty
              ? _EmptyStateView(
                  icon: _controller.favoritesOnly
                      ? Icons.bookmark_border_rounded
                      : Icons.search_off_rounded,
                  title: _controller.favoritesOnly
                      ? 'Belum ada kutipan favorit'
                      : 'Kutipan tidak ditemukan',
                  detail: _controller.favoritesOnly
                      ? 'Simpan kutipan pilihan untuk membacanya kembali dengan cepat.'
                      : 'Tidak ada kutipan yang cocok dengan filter saat ini.',
                  actionLabel: 'Tampilkan semua',
                  onAction: () {
                    _quoteSearchController.clear();
                    _controller.clearQuoteFilters();
                  },
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    if (showDailyCard) ...[
                      _DailyQuoteCard(
                        quote: _controller.todayQuote!,
                        isFavorite: _controller.isQuoteFavorite(
                          _controller.todayQuote!.id,
                        ),
                        onCopy: () => _copyText(
                          _controller.todayQuote!.copyText,
                          'Kutipan beserta rujukan disalin.',
                        ),
                        onToggleFavorite: () =>
                            _toggleQuoteFavorite(_controller.todayQuote!),
                      ),
                      const SizedBox(height: 16),
                    ],
                    for (final quote in quotes) ...[
                      _QuoteCard(
                        quote: quote,
                        isFavorite: _controller.isQuoteFavorite(quote.id),
                        onCopy: () => _copyText(
                          quote.copyText,
                          'Kutipan beserta rujukan disalin.',
                        ),
                        onToggleFavorite: () => _toggleQuoteFavorite(quote),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildStoriesTab(BuildContext context) {
    final stories = _controller.visibleStories;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _storySearchController,
            textInputAction: TextInputAction.search,
            onChanged: _controller.setStoryQuery,
            decoration: InputDecoration(
              hintText: 'Cari kisah atau rujukan',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _controller.storyQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Hapus pencarian kisah',
                      onPressed: () {
                        _storySearchController.clear();
                        _controller.setStoryQuery('');
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
        _CategoryFilterBar(
          categories: _controller.storyCategories,
          selected: _controller.selectedStoryCategory,
          onSelected: _controller.selectStoryCategory,
        ),
        Expanded(
          child: stories.isEmpty
              ? _EmptyStateView(
                  icon: _controller.favoritesOnly
                      ? Icons.bookmark_border_rounded
                      : Icons.search_off_rounded,
                  title: _controller.favoritesOnly
                      ? 'Belum ada kisah favorit'
                      : 'Kisah tidak ditemukan',
                  detail: _controller.favoritesOnly
                      ? 'Tandai kisah yang ingin Anda simpan untuk dibaca ulang.'
                      : 'Tidak ada kisah yang cocok dengan filter saat ini.',
                  actionLabel: 'Tampilkan semua',
                  onAction: () {
                    _storySearchController.clear();
                    _controller.clearStoryFilters();
                  },
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: stories.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final story = stories[index];
                    return _StoryListCard(
                      story: story,
                      isFavorite: _controller.isStoryFavorite(story.id),
                      onTap: () => _openStory(story),
                      onToggleFavorite: () => _toggleStoryFavorite(story),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class StoryDetailScreen extends StatefulWidget {
  const StoryDetailScreen({
    super.key,
    required this.story,
    required this.controller,
    required this.onCopy,
    required this.onToggleFavorite,
  });

  final IslamicStory story;
  final QuotesStoriesController controller;
  final VoidCallback onCopy;
  final VoidCallback onToggleFavorite;

  @override
  State<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends State<StoryDetailScreen> {
  double _textScale = 1.0;

  void _adjustScale(double delta) {
    setState(() {
      _textScale = (_textScale + delta).clamp(0.85, 1.45);
    });
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.controller,
    builder: (context, _) {
      final isFavorite = widget.controller.isStoryFavorite(widget.story.id);
      final theme = Theme.of(context);
      final muted = theme.colorScheme.onSurface.withValues(alpha: 0.74);
      final bodySize = (theme.textTheme.bodyLarge?.fontSize ?? 16) * _textScale;

      return Scaffold(
        appBar: AppBar(
          title: Text(widget.story.category),
          actions: [
            IconButton(
              tooltip: 'Perkecil huruf',
              onPressed: _textScale > 0.85 ? () => _adjustScale(-0.15) : null,
              icon: const Icon(Icons.text_decrease_rounded),
            ),
            IconButton(
              tooltip: 'Perbesar huruf',
              onPressed: _textScale < 1.45 ? () => _adjustScale(0.15) : null,
              icon: const Icon(Icons.text_increase_rounded),
            ),
            IconButton(
              tooltip: 'Salin ringkasan kisah',
              onPressed: widget.onCopy,
              icon: const Icon(Icons.copy_rounded),
            ),
            IconButton(
              tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan favorit',
              onPressed: widget.onToggleFavorite,
              icon: Icon(
                isFavorite
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: isFavorite ? AppColors.gold : null,
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              widget.story.title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.story.category} · ${widget.story.readMinutes} mnt baca',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 20),
            for (final paragraph in widget.story.paragraphs) ...[
              Text(
                paragraph,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: bodySize,
                  height: 1.65,
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              color: AppColors.navy,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pelajaran (Ibrah)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    for (final lesson in widget.story.lessons) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Icon(
                              Icons.circle,
                              size: 6,
                              color: AppColors.gold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              lesson,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.parchment,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sumber rujukan',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.story.sourceRef,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
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

class _CategoryFilterBar extends StatelessWidget {
  const _CategoryFilterBar({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 48,
    child: ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FilterChip(
            label: const Text('Semua'),
            selected: selected == null,
            onSelected: (_) => onSelected(null),
          ),
        ),
        for (final category in categories)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: selected == category,
              onSelected: (_) =>
                  onSelected(selected == category ? null : category),
            ),
          ),
      ],
    ),
  );
}

class _DailyQuoteCard extends StatelessWidget {
  const _DailyQuoteCard({
    required this.quote,
    required this.isFavorite,
    required this.onCopy,
    required this.onToggleFavorite,
  });

  final IslamicQuote quote;
  final bool isFavorite;
  final VoidCallback onCopy;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kutipan hari ini · ${quote.category}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (quote.textAr != null && quote.textAr!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  quote.textAr!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 22,
                    height: 1.7,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              '"${quote.textId}"',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.parchment,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${quote.author} · ${quote.sourceRef}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.parchment.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Salin kutipan hari ini',
                  onPressed: onCopy,
                  icon: const Icon(
                    Icons.copy_rounded,
                    color: AppColors.parchment,
                  ),
                ),
                IconButton(
                  tooltip: isFavorite ? 'Hapus dari favorit' : 'Simpan favorit',
                  onPressed: onToggleFavorite,
                  icon: Icon(
                    isFavorite
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isFavorite ? AppColors.gold : AppColors.parchment,
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

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.isFavorite,
    required this.onCopy,
    required this.onToggleFavorite,
  });

  final IslamicQuote quote;
  final bool isFavorite;
  final VoidCallback onCopy;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.72);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quote.category,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (quote.textAr != null && quote.textAr!.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  quote.textAr!,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'AmiriQuran',
                    fontSize: 22,
                    height: 1.7,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              '"${quote.textId}"',
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.author,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        quote.sourceRef,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Salin kutipan',
                  onPressed: onCopy,
                  icon: Icon(Icons.copy_rounded, color: muted),
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
          ],
        ),
      ),
    );
  }
}

class _StoryListCard extends StatelessWidget {
  const _StoryListCard({
    required this.story,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final IslamicStory story;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.74);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${story.category} · ${story.readMinutes} mnt baca',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: muted),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      story.sourceRef,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
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

class _EmptyStateView extends StatelessWidget {
  const _EmptyStateView({
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
