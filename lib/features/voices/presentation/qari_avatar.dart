import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../data/voice_catalog.dart';

/// Circular qari portrait backed by a bundled asset with a monogram fallback.
class QariAvatar extends StatelessWidget {
  const QariAvatar({
    super.key,
    required this.voice,
    this.size = 52,
    this.selected = false,
  });

  final Voice voice;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final asset = voice.avatarAsset;
    final borderColor = selected
        ? AppColors.gold
        : colors.outlineVariant.withValues(alpha: 0.55);

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(1.5),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.surfaceContainerHighest,
        border: Border.all(
          color: borderColor,
          width: selected ? 1.8 : 1.0,
        ),
      ),
      child: ClipOval(
        child: asset != null
            ? Image.asset(
                asset,
                width: size,
                height: size,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, _, _) =>
                    _MonogramFallback(name: voice.name, size: size),
              )
            : _MonogramFallback(name: voice.name, size: size),
      ),
    );
  }
}

class _MonogramFallback extends StatelessWidget {
  const _MonogramFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      color: isDark ? AppColors.navy : AppColors.blue.withValues(alpha: 0.12),
      alignment: Alignment.center,
      child: Text(
        _qariInitials(name),
        style: TextStyle(
          color: isDark ? AppColors.gold : AppColors.navy,
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

String _qariInitials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where(
        (part) =>
            part.isNotEmpty &&
            part.toLowerCase() != 'bin' &&
            part.toLowerCase() != 'al',
      )
      .map((part) => part.replaceFirst(RegExp(r'^(Al|As|Ash)-', caseSensitive: false), ''))
      .where((part) => part.isNotEmpty)
      .toList(growable: false);
  if (parts.isEmpty) return 'Q';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
}
