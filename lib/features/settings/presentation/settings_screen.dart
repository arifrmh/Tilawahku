import 'package:flutter/material.dart';

import '../../../core/preferences/app_preferences.dart';
import '../../about/presentation/about_screen.dart';
import '../../download/presentation/download_screen.dart';
import '../../voices/data/voice_catalog.dart';
import '../../voices/presentation/voice_selection_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.preferences,
    required this.onSetDarkMode,
  });

  final AppPreferences preferences;
  final ValueChanged<bool> onSetDarkMode;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const double _minTextScale = 0.8;
  static const double _maxTextScale = 1.8;
  static const double _stepTextScale = 0.1;

  bool _darkMode = false;
  bool _translationVisible = true;
  double _textScale = 1.0;
  String? _selectedVoiceName;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final darkMode = await widget.preferences.darkMode;
      final translationVisible = await widget.preferences.translationVisible;
      final textScale = await widget.preferences.arabicTextScale;
      final voiceId = await widget.preferences.selectedVoiceId;
      String? voiceName;
      if (voiceId != null) {
        try {
          final voices = await const VoiceCatalog().load();
          for (final voice in voices) {
            if (voice.id == voiceId) {
              voiceName = voice.name;
              break;
            }
          }
        } on Object {
          voiceName = null;
        }
      }
      if (!mounted) return;
      setState(() {
        _darkMode = darkMode;
        _translationVisible = translationVisible;
        _textScale = textScale.clamp(_minTextScale, _maxTextScale);
        _selectedVoiceName = voiceName;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = error.toString();
        });
      }
    }
  }

  Future<void> _saveDarkMode(bool value) async {
    setState(() => _darkMode = value);
    widget.onSetDarkMode(value);
    try {
      await widget.preferences.setDarkMode(value);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal menyimpan tema: $error');
      }
    }
  }

  Future<void> _saveTranslation(bool value) async {
    setState(() => _translationVisible = value);
    try {
      await widget.preferences.setTranslationVisible(value);
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = 'Gagal menyimpan preferensi terjemahan: $error',
        );
      }
    }
  }

  Future<void> _saveTextScale(double value) async {
    final normalized =
        ((value * 10).round() / 10).clamp(_minTextScale, _maxTextScale);
    setState(() => _textScale = normalized);
    try {
      await widget.preferences.setArabicTextScale(normalized);
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Gagal menyimpan ukuran teks: $error');
      }
    }
  }

  Future<void> _openVoiceSelection() async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => VoiceSelectionScreen(
          preferences: widget.preferences,
          onSetDarkMode: widget.onSetDarkMode,
          allowBack: true,
        ),
      ),
    );
    if (mounted) {
      await _loadSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pengaturan')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final scalePercent = (_textScale * 100).round();

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: TextStyle(color: colors.error)),
            ),
          const _SectionHeader(title: 'Tampilan'),
          const SizedBox(height: 8),
          _GroupedCard(
            child: Column(
              children: [
                SwitchListTile(
                  value: _darkMode,
                  title: Text(
                    'Mode gelap',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Nyaman dibaca pada kondisi minim cahaya',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  secondary: const _SettingIconBox(
                    icon: Icons.dark_mode_outlined,
                  ),
                  onChanged: _saveDarkMode,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 62,
                  color: colors.outlineVariant.withValues(alpha: 0.35),
                ),
                SwitchListTile(
                  value: _translationVisible,
                  title: Text(
                    'Tampilkan terjemahan',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Tampilkan arti Bahasa Indonesia di bawah ayat',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  secondary: const _SettingIconBox(
                    icon: Icons.translate_rounded,
                  ),
                  onChanged: _saveTranslation,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Ukuran teks Arab'),
          const SizedBox(height: 8),
          _GroupedCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const _SettingIconBox(icon: Icons.format_size_rounded),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Ukuran huruf mushaf',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$scalePercent%',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                      if ((_textScale - 1.0).abs() > 0.01) ...[
                        const SizedBox(width: 4),
                        TextButton(
                          onPressed: () => _saveTextScale(1.0),
                          child: const Text('Reset'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontFamily: 'AmiriQuran',
                        fontSize: 24 * _textScale,
                        height: 1.85,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Perkecil teks Arab',
                        onPressed: _textScale <= _minTextScale + 0.001
                            ? null
                            : () => _saveTextScale(_textScale - _stepTextScale),
                        icon: const Icon(Icons.remove_rounded),
                      ),
                      Expanded(
                        child: Slider(
                          value: _textScale,
                          min: _minTextScale,
                          max: _maxTextScale,
                          divisions: 10,
                          label: '$scalePercent%',
                          onChanged: _saveTextScale,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Perbesar teks Arab',
                        onPressed: _textScale >= _maxTextScale - 0.001
                            ? null
                            : () => _saveTextScale(_textScale + _stepTextScale),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Audio dan penyimpanan'),
          const SizedBox(height: 8),
          _GroupedCard(
            child: Column(
              children: [
                ListTile(
                  minTileHeight: 64,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: const _SettingIconBox(
                    icon: Icons.record_voice_over_outlined,
                  ),
                  title: Text(
                    'Ganti suara',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _selectedVoiceName ?? 'Pilih qari murottal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: _openVoiceSelection,
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 62,
                  color: colors.outlineVariant.withValues(alpha: 0.35),
                ),
                ListTile(
                  minTileHeight: 64,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  leading: const _SettingIconBox(
                    icon: Icons.download_outlined,
                  ),
                  title: Text(
                    'Kelola unduhan',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Unduh paket audio juz atau surah untuk mode offline',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.72),
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                  onTap: () => Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => DownloadScreen(
                        preferences: widget.preferences,
                        onSetDarkMode: widget.onSetDarkMode,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const _SectionHeader(title: 'Informasi aplikasi'),
          const SizedBox(height: 8),
          _GroupedCard(
            child: ListTile(
              minTileHeight: 64,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 4,
              ),
              leading: const _SettingIconBox(icon: Icons.info_outline_rounded),
              title: Text(
                'Tentang & Sumber',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Sumber teks Al-Qur’an, atribusi, dan lisensi',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.72),
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: colors.onSurface.withValues(alpha: 0.5),
              ),
              onTap: () => Navigator.of(context).push<void>(
                MaterialPageRoute<void>(builder: (_) => const AboutScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

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

class _GroupedCard extends StatelessWidget {
  const _GroupedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    margin: EdgeInsets.zero,
    clipBehavior: Clip.antiAlias,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: Theme.of(
          context,
        ).colorScheme.outlineVariant.withValues(alpha: 0.45),
      ),
    ),
    child: child,
  );
}

class _SettingIconBox extends StatelessWidget {
  const _SettingIconBox({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: primary),
    );
  }
}
