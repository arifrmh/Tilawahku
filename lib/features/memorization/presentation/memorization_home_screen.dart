import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../reading/data/reading_repository.dart';
import '../data/memorization_repository.dart';
import '../domain/memorization_models.dart';
import 'memorization_program_detail_screen.dart';
import 'memorization_program_form_screen.dart';

class MemorizationHomeScreen extends StatefulWidget {
  const MemorizationHomeScreen({
    super.key,
    required this.repository,
    required this.readingRepository,
  });

  final MemorizationRepository repository;
  final ReadingRepository readingRepository;

  @override
  State<MemorizationHomeScreen> createState() => _MemorizationHomeScreenState();
}

class _MemorizationHomeScreenState extends State<MemorizationHomeScreen> {
  List<MemorizationProgram>? _programs;
  Object? _error;
  bool _loading = true;
  int _loadGeneration = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final generation = ++_loadGeneration;
    try {
      final programs = await widget.repository.getPrograms();
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _programs = programs;
        _error = null;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _createProgram() async {
    final created = await Navigator.of(context).push<MemorizationProgram>(
      MaterialPageRoute(
        builder: (_) => MemorizationProgramFormScreen(
          repository: widget.repository,
          readingRepository: widget.readingRepository,
        ),
      ),
    );
    if (!mounted || created == null) return;
    setState(() {
      final current = _programs ?? const <MemorizationProgram>[];
      _programs = [
        created,
        ...current.where((item) => item.id != created.id),
      ];
      _error = null;
      _loading = false;
    });
    await _reload();
    if (!mounted) return;
    await _openProgram(created);
  }

  Future<void> _openProgram(MemorizationProgram program) async {
    final deleted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MemorizationProgramDetailScreen(
          programId: program.id,
          repository: widget.repository,
          readingRepository: widget.readingRepository,
        ),
      ),
    );
    if (!mounted) return;
    if (deleted == true && _programs != null) {
      setState(() {
        _programs = _programs!
            .where((item) => item.id != program.id)
            .toList(growable: false);
      });
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Hafalan Al-Qur’an')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _createProgram,
      icon: const Icon(Icons.add_rounded),
      label: const Text('Program baru'),
    ),
    body: _buildBody(),
  );

  Widget _buildBody() {
    if (_error != null && _programs == null) {
      return _MessageState(
        icon: Icons.error_outline_rounded,
        message: 'Gagal memuat program hafalan.',
        detail: '$_error',
        action: TextButton(onPressed: _reload, child: const Text('Coba lagi')),
      );
    }
    if (_loading && _programs == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final programs = _programs ?? const <MemorizationProgram>[];
    if (programs.isEmpty) {
      return _MessageState(
        icon: Icons.menu_book_outlined,
        message: 'Belum ada program hafalan.',
        detail: 'Pilih surah, juz, atau rentang ayat untuk mulai menghafal.',
        action: FilledButton.icon(
          onPressed: _createProgram,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Buat program'),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          const Text(
            'Program hafalan tersimpan di perangkat dan dapat digunakan '
            'secara offline.',
          ),
          const SizedBox(height: 12),
          for (final program in programs)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.navy,
                  child: Icon(Icons.psychology_alt, color: AppColors.gold),
                ),
                title: Text(program.name),
                subtitle: Text(
                  '${program.scope.label} · ${program.totalAyahs} ayat · '
                  'Target ${program.dailyTarget}/hari',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openProgram(program),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.message,
    required this.detail,
    this.action,
  });

  final IconData icon;
  final String message;
  final String detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 52, color: AppColors.gold),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(detail, textAlign: TextAlign.center),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    ),
  );
}
