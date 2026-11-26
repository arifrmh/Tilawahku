import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/assessment_attempt.dart';
import 'highlighted_ayah_text.dart';
import 'recitation_assessment_controller.dart';

const TextStyle _arabicStyle = TextStyle(
  fontFamily: 'AmiriQuran',
  fontSize: 20,
  height: 1.6,
);

class AssessmentPanel extends StatelessWidget {
  const AssessmentPanel({
    super.key,
    required this.controller,
    required this.targetText,
    this.showHighlightedAyah = true,
  });

  final RecitationAssessmentController controller;
  final String targetText;
  final bool showHighlightedAyah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.mic_none_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Penilaian bacaan',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  _PhaseBadge(phase: controller.phase),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in AssessmentMode.values)
                    ChoiceChip(
                      label: Text(mode.label),
                      selected: controller.mode == mode,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => controller.setMode(mode),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                controller.mode == AssessmentMode.latihan
                    ? 'Teks ayat tetap terlihat selama rekaman.'
                    : 'Teks ayat disembunyikan sampai rekaman selesai.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ..._body(context),
              const SizedBox(height: 8),
              Text(
                controller.isLocalRecordingOnly
                    ? 'Rekaman disimpan sementara selama halaman terbuka untuk '
                          'diputar ulang dan memeriksa hafalan secara mandiri.'
                    : 'Penilaian hanya membandingkan kata dengan teks ayat. '
                          'Tajwid, makhraj, dan sifat huruf tidak dinilai.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _body(BuildContext context) {
    final theme = Theme.of(context);
    final attempt = controller.attempt;
    if (controller.phase == AssessmentPhase.scored && attempt != null) {
      return [
        _Result(attempt: attempt, showHighlightedAyah: showHighlightedAyah),
        if (controller.message != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (controller.hasRecording) _playbackButton(),
            TextButton.icon(
              onPressed: controller.canRecord
                  ? controller.startRecording
                  : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Rekam ulang'),
            ),
          ],
        ),
      ];
    }
    if (controller.phase == AssessmentPhase.recorded) {
      final seconds = (controller.recordedSeconds ?? 0).toStringAsFixed(1);
      return [
        Text(
          'Rekaman siap didengar · $seconds dtk',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Model penilaian otomatis belum terpasang di perangkat ini. '
          'Putar rekaman untuk memeriksa hafalan Anda secara mandiri.',
          style: theme.textTheme.bodySmall,
        ),
        if (controller.message != null) ...[
          const SizedBox(height: 8),
          Text(
            controller.message!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _playbackButton(),
            TextButton.icon(
              onPressed: controller.canRecord
                  ? controller.startRecording
                  : null,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Rekam ulang'),
            ),
          ],
        ),
      ];
    }
    return switch (controller.phase) {
      AssessmentPhase.unavailable => [
        Text(
          'Belum tersedia di platform ini',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Build ini belum memuat engine ASR, jadi bacaan belum dapat '
          'dianalisis. Latihan hafalan tetap berjalan seperti biasa.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        _recordButton(context),
      ],
      AssessmentPhase.preparing || AssessmentPhase.processing => [
        Row(
          children: [
            const SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                controller.progressMessage ??
                    (controller.phase == AssessmentPhase.preparing
                        ? 'Menyiapkan mikrofon…'
                        : 'Memproses rekaman…'),
              ),
            ),
          ],
        ),
        if (controller.phase == AssessmentPhase.preparing &&
            controller.progressFraction != null) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: controller.progressFraction,
              minHeight: 5,
            ),
          ),
        ],
      ],
      AssessmentPhase.recording => [
        Text(
          controller.mode == AssessmentMode.setoran
              ? 'Merekam · baca dari hafalan'
              : 'Merekam · baca sambil melihat ayat',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 10),
        _recordButton(context),
      ],
      AssessmentPhase.failed => [
        Text(
          controller.message ?? 'Penilaian gagal.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 10),
        _recordButton(context),
      ],
      AssessmentPhase.recorded ||
      AssessmentPhase.scored ||
      AssessmentPhase.idle => [
        Text(
          'Rekam bacaan ayat ini untuk mendengarkan ulang atau menilai '
          'kesesuaian kata dengan teks ayat.',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 10),
        _recordButton(context),
      ],
    };
  }

  Widget _playbackButton() => FilledButton.tonalIcon(
    onPressed: controller.togglePlayback,
    icon: Icon(
      controller.isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
      size: 18,
    ),
    label: Text(controller.isPlaying ? 'Hentikan' : 'Putar rekaman'),
  );

  Widget _recordButton(BuildContext context) => FilledButton.icon(
    onPressed: controller.isRecording
        ? () => controller.stopAndScore(targetText)
        : controller.canRecord
        ? controller.startRecording
        : null,
    icon: Icon(
      controller.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
      size: 18,
    ),
    label: Text(
      controller.isRecording
          ? (controller.isLocalRecordingOnly
                ? 'Berhenti & simpan'
                : 'Berhenti & nilai')
          : 'Rekam bacaan',
    ),
  );
}

class _PhaseBadge extends StatelessWidget {
  const _PhaseBadge({required this.phase});

  final AssessmentPhase phase;

  @override
  Widget build(BuildContext context) => Text(
    switch (phase) {
      AssessmentPhase.unavailable => 'belum tersedia',
      AssessmentPhase.idle => 'siap',
      AssessmentPhase.preparing => 'menyiapkan',
      AssessmentPhase.recording => 'merekam',
      AssessmentPhase.processing => 'memproses',
      AssessmentPhase.recorded => 'terekam',
      AssessmentPhase.scored => 'selesai',
      AssessmentPhase.failed => 'gagal',
    },
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.primary,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Result extends StatelessWidget {
  const _Result({
    required this.attempt,
    required this.showHighlightedAyah,
  });

  final AssessmentAttempt attempt;
  final bool showHighlightedAyah;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final comparison = attempt.comparison;
    final alignment = attempt.alignment;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (alignment != null) ...[
          RecitationVerdictBanner(alignment: alignment),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                comparison.assessable
                    ? 'Kesesuaian kata: ${comparison.matchPercent.toStringAsFixed(1)} % '
                          '(${comparison.wordEdits} perbaikan dari '
                          '${comparison.referenceWordCount} kata)'
                    : 'Unscorable · bacaan belum dapat dibandingkan',
                style: theme.textTheme.titleSmall,
              ),
            ),
            Text(
              '${attempt.audioSeconds.toStringAsFixed(1)} dtk',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (attempt.note != null) ...[
          const SizedBox(height: 6),
          Text(attempt.note!, style: theme.textTheme.bodySmall),
        ],
        if (showHighlightedAyah && comparison.assessable && alignment != null) ...[
          const SizedBox(height: 10),
          Text(
            'Sorotan koreksi per kata',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          HighlightedAyahText(
            alignment: alignment,
            fontSize: 22,
            showCorrectionDetails: false,
          ),
        ],
        if (comparison.assessable) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _CountChip(label: 'Cocok', count: comparison.matched.length),
              _CountChip(label: 'Berubah', count: comparison.changed.length),
              _CountChip(label: 'Terlewat', count: comparison.missing.length),
              _CountChip(label: 'Tambahan', count: comparison.extra.length),
            ],
          ),
          if (comparison.changed.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Kata yang berubah atau tertukar',
              style: theme.textTheme.bodySmall,
            ),
            for (final change in comparison.changed)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        change.recognized,
                        textAlign: TextAlign.end,
                        textDirection: TextDirection.rtl,
                        style: _arabicStyle,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        change.expected,
                        textDirection: TextDirection.rtl,
                        style: _arabicStyle,
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (comparison.missing.isNotEmpty)
            _WordList(label: 'Kata yang terlewat', words: comparison.missing),
          if (comparison.extra.isNotEmpty)
            _WordList(label: 'Kata tambahan', words: comparison.extra),
          if (comparison.matched.isNotEmpty)
            _WordList(label: 'Kata yang cocok', words: comparison.matched),
        ],
        const SizedBox(height: 10),
        Text('Transkrip hasil pengenalan', style: theme.textTheme.bodySmall),
        Text(
          attempt.transcript.isEmpty ? '(kosong)' : attempt.transcript,
          textAlign: TextAlign.end,
          textDirection: TextDirection.rtl,
          style: _arabicStyle,
        ),
      ],
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: count == 0
          ? AppColors.parchment.withValues(alpha: 0.35)
          : AppColors.blue,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      '$label $count',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: count == 0
            ? Theme.of(context).colorScheme.onSurface
            : AppColors.parchment,
      ),
    ),
  );
}

class _WordList extends StatelessWidget {
  const _WordList({required this.label, required this.words});

  final String label;
  final List<String> words;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label (${words.length})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 2),
        Text(
          words.join(' · '),
          textAlign: TextAlign.end,
          textDirection: TextDirection.rtl,
          style: _arabicStyle,
        ),
      ],
    ),
  );
}
