import 'package:flutter/material.dart';

import '../domain/arabic_comparison.dart';

class HighlightedAyahText extends StatelessWidget {
  const HighlightedAyahText({
    super.key,
    required this.alignment,
    this.fontSize = 24,
    this.showLegend = true,
    this.showCorrectionDetails = true,
  });

  final AyahWordAlignment alignment;
  final double fontSize;
  final bool showLegend;
  final bool showCorrectionDetails;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final substitutedWords = alignment.words
        .where(
          (word) =>
              word.verdict == AyahWordVerdict.substituted &&
              word.recognizedWord != null &&
              word.recognizedWord!.isNotEmpty,
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          textDirection: TextDirection.rtl,
          alignment: WrapAlignment.start,
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final word in alignment.words)
              _WordHighlightPill(
                word: word,
                isDark: isDark,
                fontSize: fontSize,
              ),
          ],
        ),
        if (showLegend) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _LegendBadge(
                icon: Icons.check_circle_outline_rounded,
                label: 'Benar',
                colors: _colorsFor(AyahWordVerdict.correct, isDark),
              ),
              _LegendBadge(
                icon: Icons.cancel_outlined,
                label: 'Salah / tertukar',
                colors: _colorsFor(AyahWordVerdict.substituted, isDark),
              ),
              _LegendBadge(
                icon: Icons.remove_circle_outline_rounded,
                label: 'Terlewat',
                colors: _colorsFor(AyahWordVerdict.missing, isDark),
              ),
            ],
          ),
        ],
        if (showCorrectionDetails && substitutedWords.isNotEmpty) ...[
          const SizedBox(height: 14),
          _SubstitutedCorrectionsList(
            words: substitutedWords,
            isDark: isDark,
          ),
        ],
      ],
    );
  }
}

class RecitationVerdictBanner extends StatelessWidget {
  const RecitationVerdictBanner({
    super.key,
    required this.alignment,
  });

  final AyahWordAlignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final verdict = alignment.verdict;
    final palette = switch (verdict) {
      RecitationVerdict.accurate => _colorsFor(AyahWordVerdict.correct, isDark),
      RecitationVerdict.needsReview => _colorsFor(
        AyahWordVerdict.missing,
        isDark,
      ),
      RecitationVerdict.needsCorrection => _colorsFor(
        AyahWordVerdict.substituted,
        isDark,
      ),
      RecitationVerdict.unscorable => (
        background: theme.colorScheme.surfaceContainerHighest,
        border: theme.colorScheme.outlineVariant,
        foreground: theme.colorScheme.onSurface,
      ),
    };
    final icon = switch (verdict) {
      RecitationVerdict.accurate => Icons.verified_rounded,
      RecitationVerdict.needsReview => Icons.info_outline_rounded,
      RecitationVerdict.needsCorrection => Icons.error_outline_rounded,
      RecitationVerdict.unscorable => Icons.help_outline_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: palette.foreground, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alignment.assessable
                      ? '${verdict.title} (${alignment.comparison.matchPercent.toStringAsFixed(0)}%)'
                      : verdict.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  verdict.guidance,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: palette.foreground,
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

class _WordHighlightPill extends StatelessWidget {
  const _WordHighlightPill({
    required this.word,
    required this.isDark,
    required this.fontSize,
  });

  final AlignedAyahWord word;
  final bool isDark;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsFor(word.verdict, isDark);
    final isCorrect = word.verdict == AyahWordVerdict.correct;
    final semanticDetail = word.recognizedWord == null
        ? '${word.displayWord}, ${word.verdict.label}'
        : '${word.displayWord}, ${word.verdict.label}, terbaca ${word.recognizedWord}';

    return Semantics(
      label: semanticDetail,
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colors.background,
            borderRadius: BorderRadius.circular(10),
            border: isCorrect
                ? Border.all(color: colors.border.withValues(alpha: 0.35))
                : Border(
                    top: BorderSide(color: colors.border, width: 1.2),
                    left: BorderSide(color: colors.border, width: 1.2),
                    right: BorderSide(color: colors.border, width: 1.2),
                    bottom: BorderSide(color: colors.border, width: 2.5),
                  ),
          ),
          child: Text(
            word.displayWord,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'AmiriQuran',
              fontSize: fontSize,
              height: 1.65,
              color: colors.foreground,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubstitutedCorrectionsList extends StatelessWidget {
  const _SubstitutedCorrectionsList({
    required this.words,
    required this.isDark,
  });

  final List<AlignedAyahWord> words;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColors = _colorsFor(AyahWordVerdict.substituted, isDark);
    final correctColors = _colorsFor(AyahWordVerdict.correct, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Perbaikan bacaan',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        for (final word in words)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: errorColors.border.withValues(alpha: 0.55),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Terbaca',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: errorColors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        word.recognizedWord!,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 20,
                          height: 1.5,
                          color: errorColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Seharusnya',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: correctColors.foreground,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        word.displayWord,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'AmiriQuran',
                          fontSize: 20,
                          height: 1.5,
                          color: correctColors.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _LegendBadge extends StatelessWidget {
  const _LegendBadge({
    required this.icon,
    required this.label,
    required this.colors,
  });

  final IconData icon;
  final String label;
  final ({Color background, Color border, Color foreground}) colors;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: colors.background,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: colors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: colors.foreground),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colors.foreground,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

({Color background, Color border, Color foreground}) _colorsFor(
  AyahWordVerdict verdict,
  bool isDark,
) => switch (verdict) {
  AyahWordVerdict.correct =>
    isDark
        ? (
            background: const Color(0xFF153B24),
            border: const Color(0xFF66BB6A),
            foreground: const Color(0xFFD7F5DF),
          )
        : (
            background: const Color(0xFFE6F4EA),
            border: const Color(0xFF1E7E34),
            foreground: const Color(0xFF0D4720),
          ),
  AyahWordVerdict.substituted =>
    isDark
        ? (
            background: const Color(0xFF4A1818),
            border: const Color(0xFFEF9A9A),
            foreground: const Color(0xFFFFE4E4),
          )
        : (
            background: const Color(0xFFFDECEA),
            border: const Color(0xFFC62828),
            foreground: const Color(0xFF7F1212),
          ),
  AyahWordVerdict.missing =>
    isDark
        ? (
            background: const Color(0xFF473110),
            border: const Color(0xFFFFCA28),
            foreground: const Color(0xFFFFF0C2),
          )
        : (
            background: const Color(0xFFFFF4E0),
            border: const Color(0xFFB26A00),
            foreground: const Color(0xFF663C00),
          ),
};
