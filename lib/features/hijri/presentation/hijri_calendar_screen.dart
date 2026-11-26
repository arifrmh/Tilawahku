import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../prayer/data/prayer_repository.dart';
import '../../prayer/presentation/prayer_times_screen.dart';
import '../domain/hijri_models.dart';
import 'hijri_calendar_controller.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key, this.controller});

  /// Hanya untuk pengujian.
  final HijriCalendarController? controller;

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  late final HijriCalendarController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        HijriCalendarController(prayerRepository: PrayerRepository());
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _openLocationSettings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PrayerTimesScreen()),
    );
    if (!mounted) return;
    await _controller.reloadLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Hijriah'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _controller.busy ? null : _controller.refresh,
            tooltip: 'Muat ulang',
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          switch (_controller.state) {
            case HijriLoadState.loading:
              return const Center(child: CircularProgressIndicator());
            case HijriLoadState.needsLocation:
              return _buildNeedsLocation(context);
            case HijriLoadState.failed:
              return _buildError(context);
            case HijriLoadState.ready:
              return _buildCalendar(context);
          }
        },
      ),
    );
  }

  Widget _buildNeedsLocation(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.76);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_outlined, size: 56, color: muted),
            const SizedBox(height: 16),
            Text(
              'Kalender Hijriah membutuhkan lokasi',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Atur lokasi terlebih dahulu di menu Waktu Salat.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _openLocationSettings,
              icon: const Icon(Icons.place_outlined),
              label: const Text('Buka Pengaturan Lokasi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.76);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 56, color: muted),
            const SizedBox(height: 16),
            Text(
              'Kalender tidak dapat dimuat',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _controller.errorMessage ?? 'Terjadi kesalahan.',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _controller.refresh,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final month = _controller.month;
    if (month == null) return const SizedBox();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.74);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentDateCard(context),
          const SizedBox(height: 16),
          _buildMonthNavigation(context),
          const SizedBox(height: 12),
          _buildCalendarGrid(context),
          const SizedBox(height: 16),
          _buildSelectedDateDetails(context),
          const SizedBox(height: 16),
          _buildIslamicEvents(context),
          const SizedBox(height: 16),
          _buildAdjustmentSettings(context),
          if (_controller.notice != null) ...[
            const SizedBox(height: 12),
            Text(
              _controller.notice!,
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentDateCard(BuildContext context) {
    final current = _controller.month?.currentHijriDate;
    if (current == null) return const SizedBox();
    final theme = Theme.of(context);
    final weekday = gregorianWeekdayNameId(
      current.gregorianDate,
      fallback: current.weekdayEn,
    );

    return Card(
      color: AppColors.navy,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal Hijriah Hari Ini',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.parchment.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              current.displayLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.parchment,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              current.arabicLabel,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 20,
                height: 1.5,
                fontFamily: 'AmiriQuran',
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$weekday · ${current.gregorianDate}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.parchment.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthNavigation(BuildContext context) {
    final month = _controller.month;
    if (month == null) return const SizedBox();

    const monthNames = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return Row(
      children: [
        IconButton(
          tooltip: 'Bulan sebelumnya',
          onPressed: _controller.busy ? null : _controller.previousMonth,
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text(
            '${monthNames[month.gregorianMonth - 1]} ${month.gregorianYear}',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
        ),
        IconButton(
          tooltip: 'Bulan berikutnya',
          onPressed: _controller.busy ? null : _controller.nextMonth,
          icon: const Icon(Icons.chevron_right_rounded),
        ),
      ],
    );
  }

  Widget _buildCalendarGrid(BuildContext context) {
    final month = _controller.month;
    if (month == null) return const SizedBox();

    final days = month.days;
    if (days.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Data tanggal untuk bulan ini belum tersedia.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    // Geser hari pertama ke kolom hari yang tepat (Min=0, Sen=1, ..., Sab=6).
    final firstDate =
        DateTime.tryParse(days.first.gregorianDate) ??
        DateTime(month.gregorianYear, month.gregorianMonth, 1);
    final leadingEmpty = firstDate.weekday % 7;

    final cells = <HijriCalendarDay?>[
      for (var i = 0; i < leadingEmpty; i++) null,
      ...days,
    ];
    while (cells.length % 7 != 0) {
      cells.add(null);
    }

    final weeks = <List<HijriCalendarDay?>>[
      for (var i = 0; i < cells.length; i += 7) cells.sublist(i, i + 7),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Row(
              children: [
                Expanded(child: _WeekdayLabel('Min')),
                Expanded(child: _WeekdayLabel('Sen')),
                Expanded(child: _WeekdayLabel('Sel')),
                Expanded(child: _WeekdayLabel('Rab')),
                Expanded(child: _WeekdayLabel('Kam')),
                Expanded(child: _WeekdayLabel('Jum')),
                Expanded(child: _WeekdayLabel('Sab')),
              ],
            ),
            const Divider(height: 16),
            for (final week in weeks)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    for (final day in week)
                      Expanded(
                        child: day == null
                            ? const SizedBox(height: 48)
                            : _CalendarDayTile(
                                day: day,
                                isSelected: _controller.selectedDay == day,
                                onTap: () => _controller.selectDay(day),
                              ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedDateDetails(BuildContext context) {
    final selected = _controller.selectedDay;
    if (selected == null) return const SizedBox();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.76);
    final weekday = gregorianWeekdayNameId(
      selected.gregorianDate,
      fallback: selected.weekdayEn,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal Terpilih',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
            const SizedBox(height: 8),
            Text(
              selected.displayLabel,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              selected.arabicLabel,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 18,
                height: 1.5,
                fontFamily: 'AmiriQuran',
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$weekday · ${selected.gregorianDate}',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            if (selected.events.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final event in selected.events)
                Text(
                  '${event.nameId}: ${event.description}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIslamicEvents(BuildContext context) {
    final events = IslamicEvents.instance.all;
    if (events.isEmpty) return const SizedBox();
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.74);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tanggal Penting Islam',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            for (final event in events)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _EventTile(event: event),
              ),
            Text(
              'Catatan: Tanggal di atas berdasarkan perhitungan layanan. '
              'Penetapan resmi dapat berbeda sesuai rukyat lokal.',
              style: theme.textTheme.bodySmall?.copyWith(color: muted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdjustmentSettings(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.76);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Penyesuaian Tanggal Hijriah',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _controller.adjustmentLabel,
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final value in const [-2, -1, 0, 1, 2]) ...[
                  if (value != -2) const SizedBox(width: 8),
                  _AdjustmentButton(
                    label: value > 0 ? '+$value' : '$value',
                    selected: _controller.adjustment.days == value,
                    onTap: () => _controller.setAdjustment(value),
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

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.76),
        ),
      ),
    );
  }
}

class _CalendarDayTile extends StatelessWidget {
  const _CalendarDayTile({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  final HijriCalendarDay day;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasEvent = day.events.isNotEmpty;
    final dateParts = day.gregorianDate.split('-');
    final gregorianDayLabel = dateParts.length >= 3
        ? '${int.tryParse(dateParts[2]) ?? dateParts[2]}'
        : day.gregorianDate;

    final fillColor = isSelected ? colorScheme.primary : Colors.transparent;
    final primaryText = isSelected
        ? colorScheme.onPrimary
        : colorScheme.onSurface;
    final secondaryText = isSelected
        ? colorScheme.onPrimary.withValues(alpha: 0.85)
        : colorScheme.onSurface.withValues(alpha: 0.72);

    return Semantics(
      button: true,
      selected: isSelected,
      label: '${day.gregorianDate}, ${day.displayLabel}',
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: fillColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: day.isToday
                ? const BorderSide(color: AppColors.gold, width: 2)
                : BorderSide.none,
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      gregorianDayLabel,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: primaryText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      '${day.hijriDay}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: secondaryText,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (hasEvent)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventTile extends StatelessWidget {
  const _EventTile({required this.event});

  final IslamicEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.76);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.nameId,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${event.hijriDay} ${hijriMonthNameIdFor(event.hijriMonth)}',
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
        const SizedBox(height: 2),
        Text(
          event.description,
          style: theme.textTheme.bodySmall?.copyWith(color: muted),
        ),
      ],
    );
  }
}

class _AdjustmentButton extends StatelessWidget {
  const _AdjustmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(48, 48),
          backgroundColor: selected ? colorScheme.primary : null,
          foregroundColor: selected
              ? colorScheme.onPrimary
              : colorScheme.onSurface,
          side: BorderSide(
            color: selected
                ? colorScheme.primary
                : colorScheme.onSurface.withValues(alpha: 0.35),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
