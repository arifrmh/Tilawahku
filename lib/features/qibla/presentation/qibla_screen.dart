import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../prayer/presentation/prayer_setup_sheets.dart';
import '../domain/qibla_direction.dart';
import 'qibla_controller.dart';

/// Layar arah kiblat: bearing ke Ka'bah, kompas perangkat bila ada, dan dial
/// manual sebagai cadangan.
class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key, this.controller});

  /// Hanya untuk pengujian.
  final QiblaController? controller;

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with WidgetsBindingObserver {
  late final QiblaController _controller;
  double? _touchAngle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? QiblaController();
    _controller.addListener(_onChanged);
    _controller.start();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.resumeHeading();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller.pauseHeading();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() => showLocationSheet(context, _controller);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Arah Kiblat'),
      actions: [
        IconButton(
          tooltip: 'Ganti lokasi',
          onPressed: _pickLocation,
          icon: const Icon(Icons.place_outlined),
        ),
      ],
    ),
    body: switch (_controller.state) {
      QiblaLoadState.needsLocation => _NeedsLocationPanel(
        controller: _controller,
        onPickLocation: _pickLocation,
      ),
      QiblaLoadState.loading when _controller.location == null => const Center(
        child: CircularProgressIndicator(),
      ),
      _ => _QiblaBody(
        controller: _controller,
        onPickLocation: _pickLocation,
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
      ),
    },
  );

  void _onPanStart(DragStartDetails details, double side) {
    _touchAngle = _angleOf(details.localPosition, side);
  }

  void _onPanUpdate(DragUpdateDetails details, double side) {
    final previous = _touchAngle;
    final next = _angleOf(details.localPosition, side);
    _touchAngle = next;
    if (previous == null) return;
    _controller.rotateDial(alignmentDelta(from: previous, to: next));
  }

  /// Sudut posisi sentuh dari pusat dial, 0° di atas dan bertambah searah jarum.
  static double _angleOf(Offset position, double side) => normalizeDegrees(
    math.atan2(position.dx - side / 2, side / 2 - position.dy) * 180 / math.pi,
  );
}

class _QiblaBody extends StatelessWidget {
  const _QiblaBody({
    required this.controller,
    required this.onPickLocation,
    required this.onPanStart,
    required this.onPanUpdate,
  });

  final QiblaController controller;
  final VoidCallback onPickLocation;
  final void Function(DragStartDetails, double) onPanStart;
  final void Function(DragUpdateDetails, double) onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final reading = controller.reading;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        _HeadingCard(controller: controller, onChangeLocation: onPickLocation),
        if (reading != null && !reading.hasBearing) ...[
          const SizedBox(height: 12),
          _NoticeCard(message: reading.undefinedReason!.messageId),
        ],
        const SizedBox(height: 12),
        _DialCard(
          controller: controller,
          onPanStart: onPanStart,
          onPanUpdate: onPanUpdate,
        ),
        if (controller.compassMessage != null) ...[
          const SizedBox(height: 12),
          _NoticeCard(message: controller.compassMessage!),
        ],
        if (controller.locationMessage != null) ...[
          const SizedBox(height: 12),
          _NoticeCard(message: controller.locationMessage!),
        ],
        if (controller.errorMessage != null) ...[
          const SizedBox(height: 12),
          _NoticeCard(message: controller.errorMessage!),
        ],
        if (!controller.isLiveCompass) ...[
          const SizedBox(height: 12),
          const _MethodCard(),
        ],
        const SizedBox(height: 12),
        Text(
          'Sumber: koordinat Ka\'bah 21.4225° LU, 39.8262° BT dan rumus lingkaran '
          'besar. Tidak ada data lokasi yang dikirim ke server untuk menghitung '
          'arah ini.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _HeadingCard extends StatelessWidget {
  const _HeadingCard({
    required this.controller,
    required this.onChangeLocation,
  });

  final QiblaController controller;
  final VoidCallback onChangeLocation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final location = controller.location;
    final reading = controller.reading;
    return Card(
      color: AppColors.navy,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.place_outlined,
                  color: AppColors.gold,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: onChangeLocation,
                    borderRadius: BorderRadius.circular(6),
                    child: Text(
                      location?.name ?? 'Lokasi belum dipilih',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.parchment,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                if (location != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '${location.latitude.toStringAsFixed(3)}, '
                    '${location.longitude.toStringAsFixed(3)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.parchment.withValues(alpha: 0.8),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.38),
                ),
              ),
              child: Text(
                controller.headingModeLabel,
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Arah kiblat dari utara sejati',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.parchment.withValues(alpha: 0.82),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              reading?.bearingLabel ?? '--',
              style: theme.textTheme.displayMedium?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              reading == null
                  ? 'Belum ada arah'
                  : '${reading.compassPoint} · '
                        '${reading.distanceLabel} ke Ka\'bah',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.parchment,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (controller.deviceHeadingLabel != null) ...[
              const SizedBox(height: 6),
              Text(
                'Heading perangkat ${controller.deviceHeadingLabel}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.parchment.withValues(alpha: 0.8),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DialCard extends StatelessWidget {
  const _DialCard({
    required this.controller,
    required this.onPanStart,
    required this.onPanUpdate,
  });

  final QiblaController controller;
  final void Function(DragStartDetails, double) onPanStart;
  final void Function(DragUpdateDetails, double) onPanUpdate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final aligned = controller.hasReading && controller.turnDelta.abs() < 0.75;
    return Card(
      elevation: 0,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: aligned
              ? AppColors.gold
              : colors.outlineVariant.withValues(alpha: 0.45),
          width: aligned ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.isLiveCompass
                        ? 'Kompas perangkat'
                        : 'Dial manual',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  'Utara dial ${controller.dialDegrees.toStringAsFixed(0)}°',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.72),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              aligned
                  ? 'Penanda Ka\'bah berada di ujung atas: tepi atas ponsel '
                        'menghadap kiblat.'
                  : controller.isLiveCompass
                  ? 'Putar perangkat sampai penanda Ka\'bah di ujung atas.'
                  : 'Geser lingkaran sampai penanda Ka\'bah berada di ujung '
                        'atas, atau gunakan penggeser di bawah. Dial ini '
                        'bukan heading fisik perangkat.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.76),
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = math.min(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );
                  return GestureDetector(
                    onPanStart: controller.isLiveCompass
                        ? null
                        : (details) => onPanStart(details, side),
                    onPanUpdate: controller.isLiveCompass
                        ? null
                        : (details) => onPanUpdate(details, side),
                    child: CustomPaint(
                      size: Size(side, side),
                      painter: _DialPainter(
                        dialDegrees: controller.dialDegrees,
                        markerDegrees: controller.markerDegrees,
                        showMarker: controller.hasReading,
                        aligned: aligned,
                        ringColor: colors.onSurface,
                        pointerColor: colors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (!controller.isLiveCompass)
              Slider(
                value: controller.dialDegrees.clamp(0, 360),
                min: 0,
                max: 360,
                divisions: 360,
                label: '${controller.dialDegrees.toStringAsFixed(0)}°',
                onChanged: controller.setDial,
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: aligned
                          ? AppColors.gold.withValues(alpha: 0.16)
                          : colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      controller.hasReading
                          ? controller.turnHintLabel
                          : 'Belum ada arah untuk dituju',
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: aligned ? AppColors.gold : colors.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
                if (!controller.isLiveCompass) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: controller.resetDial,
                    child: const Text('Ke utara'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  const _MethodCard();

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.parchment,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cara memakai dial manual',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tentukan utara sejati (kompas yang dikalibrasi atau bayangan '
            'matahari), lalu putar lingkaran sampai label Utara menunjuk ke '
            'sana. Deklinasi magnetik tidak diterapkan otomatis.',
            style: TextStyle(color: AppColors.navy, fontSize: 13),
          ),
        ],
      ),
    ),
  );
}

class _DialPainter extends CustomPainter {
  const _DialPainter({
    required this.dialDegrees,
    required this.markerDegrees,
    required this.showMarker,
    required this.aligned,
    required this.ringColor,
    required this.pointerColor,
  });

  final double dialDegrees;
  final double markerDegrees;
  final bool showMarker;
  final bool aligned;
  final Color ringColor;
  final Color pointerColor;

  static const List<(String, double)> _cardinals = [
    ('U', 0),
    ('T', 90),
    ('S', 180),
    ('B', 270),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    const topInset = 42.0;
    const edgeInset = 18.0;
    final radius = math.max(
      24.0,
      math.min(
        size.width / 2 - edgeInset,
        (size.height - topInset - edgeInset) / 2,
      ),
    );
    final center = Offset(size.width / 2, topInset + radius);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = aligned ? AppColors.gold : ringColor.withValues(alpha: 0.85);
    canvas.drawCircle(center, radius, ring);
    canvas.drawCircle(
      center,
      radius * 0.72,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = ringColor.withValues(alpha: 0.16),
    );

    for (var degrees = 0; degrees < 360; degrees += 15) {
      final major = degrees % 45 == 0;
      final angle = _radians(degrees - dialDegrees);
      final outer = center + Offset(math.sin(angle), -math.cos(angle)) * radius;
      final inner =
          center +
          Offset(math.sin(angle), -math.cos(angle)) *
              (radius - (major ? 12 : 6));
      canvas.drawLine(
        inner,
        outer,
        Paint()
          ..strokeWidth = major ? 2 : 1
          ..color = ringColor.withValues(alpha: major ? 0.65 : 0.3),
      );
    }

    for (final (label, degrees) in _cardinals) {
      final angle = _radians(degrees - dialDegrees);
      final at =
          center + Offset(math.sin(angle), -math.cos(angle)) * (radius * 0.54);
      _text(
        canvas,
        label,
        at,
        label == 'U' ? pointerColor : ringColor.withValues(alpha: 0.85),
        15,
        FontWeight.w800,
      );
    }

    if (showMarker) {
      final angle = _radians(markerDegrees);
      final direction = Offset(math.sin(angle), -math.cos(angle));
      canvas.drawLine(
        center,
        center + direction * (radius - 6),
        Paint()
          ..strokeWidth = 3
          ..color = AppColors.gold
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawCircle(center, 4.5, Paint()..color = AppColors.gold);
      final marker = center + direction * radius;
      canvas.drawCircle(
        marker,
        12,
        Paint()..color = aligned ? AppColors.gold : AppColors.navy,
      );
      _text(
        canvas,
        'K',
        marker,
        aligned ? AppColors.navy : AppColors.parchment,
        12,
        FontWeight.w800,
      );
    }

    // Penanda tetap: tepi atas ponsel, tetap di dalam area canvas.
    final pointerTipY = center.dy - radius - 10;
    final pointer = Path()
      ..moveTo(center.dx, pointerTipY)
      ..lineTo(center.dx - 6, pointerTipY - 11)
      ..lineTo(center.dx + 6, pointerTipY - 11)
      ..close();
    canvas.drawPath(
      pointer,
      Paint()..color = aligned ? AppColors.gold : pointerColor,
    );
    _text(
      canvas,
      'PONSEL',
      Offset(center.dx, pointerTipY - 21),
      aligned ? AppColors.gold : pointerColor,
      10,
      FontWeight.w700,
    );
  }

  void _text(
    Canvas canvas,
    String value,
    Offset at,
    Color color,
    double size,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(color: color, fontSize: size, fontWeight: weight),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(at.dx - painter.width / 2, at.dy - painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.dialDegrees != dialDegrees ||
      old.markerDegrees != markerDegrees ||
      old.showMarker != showMarker ||
      old.aligned != aligned ||
      old.ringColor != ringColor ||
      old.pointerColor != pointerColor;
}

class _NeedsLocationPanel extends StatelessWidget {
  const _NeedsLocationPanel({
    required this.controller,
    required this.onPickLocation,
  });

  final QiblaController controller;
  final VoidCallback onPickLocation;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Icon(
        Icons.explore_outlined,
        size: 46,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 12),
      Text(
        'Tentukan lokasi untuk menghitung kiblat',
        style: Theme.of(context).textTheme.titleLarge,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 8),
      const Text(
        'Perhitungan hanya memakai koordinat dan rumus lingkaran besar. '
        'Koordinat yang dipilih sama dengan yang dipakai layar waktu salat dan '
        'tidak dikirim ke layanan mana pun untuk menghitung arah.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      FilledButton.icon(
        onPressed: controller.busy ? null : controller.useDeviceLocation,
        icon: const Icon(Icons.my_location_rounded),
        label: const Text('Gunakan lokasi perangkat'),
      ),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: onPickLocation,
        icon: const Icon(Icons.search_rounded),
        label: const Text('Pilih kota atau isi koordinat'),
      ),
      if (controller.locationMessage != null) ...[
        const SizedBox(height: 14),
        _NoticeCard(message: controller.locationMessage!),
      ],
      if (controller.errorMessage != null) ...[
        const SizedBox(height: 14),
        _NoticeCard(message: controller.errorMessage!),
      ],
      if (controller.busy) ...[
        const SizedBox(height: 16),
        const Center(child: LinearProgressIndicator()),
      ],
    ],
  );
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.parchment,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.navy),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: AppColors.navy, fontSize: 13),
            ),
          ),
        ],
      ),
    ),
  );
}

double _radians(double degrees) => degrees * math.pi / 180;
