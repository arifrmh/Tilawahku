import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../domain/prayer_method.dart';
import '../domain/prayer_models.dart';
import 'location_selection.dart';
import 'prayer_times_controller.dart';

/// Lembar lokasi bersama: dipakai layar waktu salat dan layar arah kiblat.
Future<void> showLocationSheet(
  BuildContext context,
  LocationSelection selection,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _LocationSheet(selection: selection),
);

Future<void> showPrayerSettingsSheet(
  BuildContext context,
  PrayerTimesController controller,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _SettingsSheet(controller: controller),
);

class _LocationSheet extends StatefulWidget {
  const _LocationSheet({required this.selection});

  final LocationSelection selection;

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  final _search = TextEditingController();
  final _name = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  String _error = '';

  @override
  void initState() {
    super.initState();
    final location = widget.selection.selectedLocation;
    if (location != null && location.source == LocationSource.manual) {
      _name.text = location.name;
      _latitude.text = location.latitude.toStringAsFixed(4);
      _longitude.text = location.longitude.toStringAsFixed(4);
    }
  }

  @override
  void dispose() {
    _search.dispose();
    _name.dispose();
    _latitude.dispose();
    _longitude.dispose();
    super.dispose();
  }

  Future<void> _submitManual() async {
    final latitude = double.tryParse(_latitude.text.replaceAll(',', '.'));
    final longitude = double.tryParse(_longitude.text.replaceAll(',', '.'));
    if (latitude == null || longitude == null) {
      setState(() => _error = 'Isi lintang dan bujur sebagai angka.');
      return;
    }
    await widget.selection.enterCoordinates(
      name: _name.text,
      latitude: latitude,
      longitude: longitude,
    );
    if (!mounted) return;
    if (widget.selection.locationMessage != null) {
      setState(() => _error = widget.selection.locationMessage!);
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final cities = query.isEmpty
        ? widget.selection.cities
        : widget.selection.cities
              .where(
                (city) =>
                    city.name.toLowerCase().contains(query) ||
                    (city.country?.toLowerCase().contains(query) ?? false),
              )
              .toList();
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Atur lokasi', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            const Text(
              'Kota di bawah dibundel dalam aplikasi (koordinat OpenStreetMap, '
              'zona waktu AlAdhan). Pilihan lain bisa diisi manual.',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: widget.selection.busy
                  ? null
                  : () async {
                      await widget.selection.useDeviceLocation();
                      if (context.mounted &&
                          widget.selection.locationMessage == null) {
                        Navigator.of(context).pop();
                      }
                    },
              icon: const Icon(Icons.my_location_rounded),
              label: const Text('Gunakan lokasi perangkat'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Cari kota',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  for (final city in cities)
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_city_rounded),
                      title: Text(city.name),
                      subtitle: Text(
                        '${city.timezoneId ?? 'zona tidak diketahui'} • '
                        '${city.latitude.toStringAsFixed(3)}, '
                        '${city.longitude.toStringAsFixed(3)}',
                      ),
                      onTap: () async {
                        await widget.selection.selectCity(city);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  if (cities.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('Kota tidak ditemukan dalam daftar lokal.'),
                    ),
                ],
              ),
            ),
            const Divider(height: 24),
            Text(
              'Koordinat manual',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'Nama lokasi',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latitude,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Lintang',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _longitude,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      labelText: 'Bujur',
                    ),
                  ),
                ),
              ],
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: const TextStyle(color: Colors.redAccent)),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _submitManual,
                child: const Text('Simpan lokasi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet({required this.controller});

  final PrayerTimesController controller;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final theme = Theme.of(context);
      final colors = theme.colorScheme;
      final settings = controller.settings;
      final hasAnyAdjustment = PrayerKind.values.any(
        (kind) =>
            kind.isSalat && (settings.adjustments.minutesFor(kind) ?? 0) != 0,
      );
      final salatKinds = [
        for (final kind in PrayerKind.values)
          if (kind.isSalat) kind,
      ];
      String? asrClock;
      final events = controller.schedule?.events;
      if (events != null) {
        for (final event in events) {
          if (event.kind == PrayerKind.asr) {
            asrClock = event.wallClock;
            break;
          }
        }
      }

      return SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Pengaturan jadwal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (controller.busy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const _SheetSectionTitle('Perhitungan jadwal'),
                const SizedBox(height: 8),
                _SheetCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<int>(
                        key: ValueKey('method-${settings.method.aladhanId}'),
                        initialValue: settings.method.aladhanId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Metode perhitungan',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          for (final method in PrayerMethod.values)
                            DropdownMenuItem(
                              value: method.aladhanId,
                              child: Text(
                                '${method.name} · ${method.angleSummary}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          controller.selectMethod(PrayerMethod.byId(value));
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Mazhab waktu Asar',
                              style: theme.textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (asrClock != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Asar $asrClock',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Menentukan kapan waktu salat Asar dimulai; waktu salat lain tidak berubah.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<AsrMadhab>(
                          segments: [
                            for (final madhab in AsrMadhab.values)
                              ButtonSegment(
                                value: madhab,
                                label: Text(
                                  madhab.labelId,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                          ],
                          selected: {settings.asrMadhab},
                          showSelectedIcon: false,
                          onSelectionChanged: (value) =>
                              controller.selectMadhab(value.first),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          settings.asrMadhab.descriptionId,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: _SheetSectionTitle('Penyesuaian menit'),
                    ),
                    if (hasAnyAdjustment)
                      TextButton(
                        onPressed: controller.resetAdjustments,
                        child: const Text('Reset'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Mengoreksi tampilan dan pengingat di perangkat secara langsung.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                ),
                _SheetCard(
                  child: Column(
                    children: [
                      for (var i = 0; i < salatKinds.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 14,
                            endIndent: 14,
                            color: colors.outlineVariant.withValues(
                              alpha: 0.35,
                            ),
                          ),
                        _AdjustmentRow(
                          kind: salatKinds[i],
                          minutes:
                              settings.adjustments.minutesFor(salatKinds[i]) ??
                              0,
                          onChanged: (minutes) =>
                              controller.setAdjustment(salatKinds[i], minutes),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _SheetSectionTitle('Pengingat salat'),
                const SizedBox(height: 8),
                _SheetCard(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: settings.remindersEnabled,
                        onChanged: controller.remindersSupportedByPlatform
                            ? (value) => controller.setRemindersEnabled(value)
                            : null,
                        title: Text(
                          'Aktifkan pengingat waktu salat',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          controller.remindersSupportedByPlatform
                              ? (!settings.remindersEnabled
                                    ? 'Pengingat sedang nonaktif.'
                                    : controller.remindersArmed
                                    ? 'Terjadwal untuk jadwal yang sedang tampil.'
                                    : 'Belum ada pengingat tersisa hari ini.')
                              : 'Tidak tersedia pada platform ini.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.72),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        key: ValueKey('lead-${settings.reminderLeadMinutes}'),
                        initialValue: settings.reminderLeadMinutes,
                        isExpanded: true,
                        decoration: InputDecoration(
                          isDense: true,
                          labelText: 'Menit sebelum waktu salat',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 3, child: Text('3 menit')),
                          DropdownMenuItem(value: 5, child: Text('5 menit')),
                          DropdownMenuItem(value: 10, child: Text('10 menit')),
                          DropdownMenuItem(value: 15, child: Text('15 menit')),
                          DropdownMenuItem(value: 20, child: Text('20 menit')),
                          DropdownMenuItem(value: 30, child: Text('30 menit')),
                        ],
                        onChanged: settings.remindersEnabled
                            ? (value) {
                                if (value != null) {
                                  controller.setReminderLead(value);
                                }
                              }
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          for (final kind in salatKinds)
                            FilterChip(
                              label: Text(kind.labelId),
                              selected:
                                  settings.reminderKinds.isEmpty ||
                                  settings.reminderKinds.contains(kind),
                              onSelected: settings.remindersEnabled
                                  ? (_) => controller.toggleReminderKind(kind)
                                  : null,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Jika tidak ada yang dipilih, semua waktu salat diingatkan. '
                        'Pengingat terjadwal bergantung pada izin notifikasi dan alarm perangkat.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.68),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _SheetSectionTitle extends StatelessWidget {
  const _SheetSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SheetCard extends StatelessWidget {
  const _SheetCard({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      color: colors.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colors.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );
  }
}

class _AdjustmentRow extends StatelessWidget {
  const _AdjustmentRow({
    required this.kind,
    required this.minutes,
    required this.onChanged,
  });

  final PrayerKind kind;
  final int minutes;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final adjusted = minutes != 0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              kind.labelId,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Kurangi 1 menit ${kind.labelId}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: minutes <= -PrayerAdjustments.maxMinutes
                ? null
                : () => onChanged(
                    (minutes - 1).clamp(
                      -PrayerAdjustments.maxMinutes,
                      PrayerAdjustments.maxMinutes,
                    ),
                  ),
            icon: const Icon(Icons.remove_rounded),
          ),
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: adjusted
                  ? AppColors.gold.withValues(alpha: 0.16)
                  : colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Text(
              '${minutes > 0 ? '+' : ''}$minutes',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: adjusted ? AppColors.gold : colors.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          IconButton(
            tooltip: 'Tambah 1 menit ${kind.labelId}',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            onPressed: minutes >= PrayerAdjustments.maxMinutes
                ? null
                : () => onChanged(
                    (minutes + 1).clamp(
                      -PrayerAdjustments.maxMinutes,
                      PrayerAdjustments.maxMinutes,
                    ),
                  ),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
    );
  }
}
