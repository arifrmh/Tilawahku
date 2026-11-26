import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/app_preferences.dart';
import '../data/tasbih_repository.dart';
import '../domain/tasbih_models.dart';
import 'tasbih_controller.dart';

class TasbihScreen extends StatefulWidget {
  const TasbihScreen({
    super.key,
    required this.preferences,
    this.controller,
  });

  final AppPreferences preferences;
  final TasbihController? controller;

  @override
  State<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  late final TasbihController _controller;
  late final bool _ownsController;

  static const List<int> _quickTargets = [33, 99, 100];

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        TasbihController(
          repository: TasbihRepository(preferences: widget.preferences),
        );
    _controller.load();
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _showCustomTargetDialog() async {
    final chosen = await showDialog<int>(
      context: context,
      builder: (_) =>
          _CustomTargetDialog(initialTarget: _controller.state.target),
    );
    if (chosen != null) await _controller.setTarget(chosen);
  }

  Future<void> _confirmReset() async {
    final state = _controller.state;
    if (state.count == 0 && state.totalCount == 0) return;
    final choice = await showDialog<_ResetChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset hitungan tasbih?'),
        content: Text(
          'Saat ini tercatat ${state.count}/${state.target} '
          '(total ${state.totalCount} hitungan). Pilih jenis reset:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
          ),
          if (state.count > 0 && state.completedRounds > 0)
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).pop(_ResetChoice.currentRound),
              child: const Text('Putaran ini saja'),
            ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_ResetChoice.all),
            child: const Text('Reset semua'),
          ),
        ],
      ),
    );
    if (choice == _ResetChoice.currentRound) {
      await _controller.resetCurrentRound();
    } else if (choice == _ResetChoice.all) {
      await _controller.resetAll();
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _controller,
    builder: (context, _) {
      final state = _controller.state;
      final preset = state.preset;
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final isCustomTarget = !_quickTargets.contains(state.target);

      return Scaffold(
        appBar: AppBar(
          title: const Text('Tasbih digital'),
          actions: [
            IconButton(
              tooltip: state.hapticEnabled
                  ? 'Matikan getar umpan balik'
                  : 'Aktifkan getar umpan balik',
              onPressed: _controller.toggleHaptic,
              icon: Icon(
                state.hapticEnabled
                    ? Icons.vibration_rounded
                    : Icons.smartphone_rounded,
              ),
            ),
            IconButton(
              tooltip: 'Reset hitungan',
              onPressed: state.count == 0 && state.totalCount == 0
                  ? null
                  : _confirmReset,
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          ],
        ),
        body: _controller.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  SizedBox(
                    height: 48,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        for (final item in tasbihPresets)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(item.title),
                              selected: state.presetId == item.id,
                              onSelected: (_) => _controller.selectPreset(item),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    color: AppColors.navy,
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            preset.arabic,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'AmiriQuran',
                              fontSize: 26,
                              height: 1.65,
                              color: AppColors.parchment,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.transliteration,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.gold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            preset.meaning,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.parchment,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            preset.sourceRef,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.parchment.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target hitungan',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final target in _quickTargets)
                                ChoiceChip(
                                  label: Text('$target'),
                                  selected: state.target == target,
                                  onSelected: (_) =>
                                      _controller.setTarget(target),
                                ),
                              ChoiceChip(
                                label: Text(
                                  isCustomTarget
                                      ? 'Kustom (${state.target})'
                                      : 'Kustom',
                                ),
                                selected: isCustomTarget,
                                onSelected: (_) => _showCustomTargetDialog(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Center(
                    child: Semantics(
                      button: true,
                      label:
                          'Hitung dzikir ${preset.title}, ${state.count} dari ${state.target}',
                      child: SizedBox(
                        width: 196,
                        height: 196,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 196,
                              height: 196,
                              child: CircularProgressIndicator(
                                value: state.progress,
                                strokeWidth: 10,
                                backgroundColor: colors.surfaceContainerHighest,
                                color: state.isTargetReached
                                    ? AppColors.gold
                                    : colors.primary,
                                strokeCap: StrokeCap.round,
                              ),
                            ),
                            Material(
                              color: theme.brightness == Brightness.dark
                                  ? colors.surfaceContainerHigh
                                  : colors.surfaceContainerLowest,
                              shape: const CircleBorder(),
                              elevation: 1,
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                key: const ValueKey('tasbih-tap-button'),
                                customBorder: const CircleBorder(),
                                onTap: _controller.tap,
                                child: SizedBox(
                                  width: 168,
                                  height: 168,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${state.count}',
                                        style: theme.textTheme.displayMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              fontFeatures: const [
                                                FontFeature.tabularFigures(),
                                              ],
                                              color: colors.onSurface,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'dari ${state.target}',
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color: colors.onSurfaceVariant,
                                            ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        state.isTargetReached
                                            ? 'Target tercapai'
                                            : 'Ketuk untuk hitung',
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: state.isTargetReached
                                                  ? colors.primary
                                                  : colors.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Putaran selesai: ${state.completedRounds} · '
                    'Total hitungan: ${state.totalCount}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.totalCount > 0
                              ? _controller.undo
                              : null,
                          icon: const Icon(Icons.undo_rounded),
                          label: const Text('Kurangi 1'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: state.count == 0 && state.totalCount == 0
                              ? null
                              : _confirmReset,
                          icon: const Icon(Icons.restart_alt_rounded),
                          label: const Text('Reset'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      );
    },
  );
}

enum _ResetChoice { currentRound, all }

class _CustomTargetDialog extends StatefulWidget {
  const _CustomTargetDialog({required this.initialTarget});

  final int initialTarget;

  @override
  State<_CustomTargetDialog> createState() => _CustomTargetDialogState();
}

class _CustomTargetDialogState extends State<_CustomTargetDialog> {
  late final TextEditingController _textController;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: '${widget.initialTarget}');
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final parsed = int.tryParse(_textController.text.trim());
    if (parsed == null ||
        parsed < TasbihState.minTarget ||
        parsed > TasbihState.maxTarget) {
      setState(() {
        _errorText = 'Masukkan angka antara 1 dan 9999.';
      });
      return;
    }
    Navigator.of(context).pop(parsed);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Target dzikir kustom'),
    content: TextField(
      controller: _textController,
      keyboardType: TextInputType.number,
      autofocus: true,
      decoration: InputDecoration(
        labelText: 'Jumlah target (1 sampai 9999)',
        errorText: _errorText,
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Batal'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Simpan')),
    ],
  );
}
