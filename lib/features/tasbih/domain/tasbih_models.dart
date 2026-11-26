class TasbihPreset {
  const TasbihPreset({
    required this.id,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.meaning,
    required this.defaultTarget,
    required this.sourceRef,
  });

  final String id;
  final String title;
  final String arabic;
  final String transliteration;
  final String meaning;
  final int defaultTarget;
  final String sourceRef;
}

const List<TasbihPreset> tasbihPresets = [
  TasbihPreset(
    id: 'subhanallah',
    title: 'Subhanallah',
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'Subhanallah',
    meaning: 'Mahasuci Allah',
    defaultTarget: 33,
    sourceRef: 'HR. Muslim no. 597 (dzikir setelah salat)',
  ),
  TasbihPreset(
    id: 'alhamdulillah',
    title: 'Alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    meaning: 'Segala puji bagi Allah',
    defaultTarget: 33,
    sourceRef: 'HR. Muslim no. 597 (dzikir setelah salat)',
  ),
  TasbihPreset(
    id: 'allahuakbar',
    title: 'Allahu Akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    meaning: 'Allah Mahabesar',
    defaultTarget: 33,
    sourceRef: 'HR. Muslim no. 597 (dzikir setelah salat)',
  ),
  TasbihPreset(
    id: 'tahlil',
    title: 'Tahlil',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
    transliteration: 'La ilaha illallahu wahdahu la syarika lah',
    meaning: 'Tiada sesembahan yang berhak disembah selain Allah semata, tiada sekutu bagi-Nya',
    defaultTarget: 100,
    sourceRef: 'HR. Al-Bukhari no. 3293 dan Muslim no. 2691',
  ),
  TasbihPreset(
    id: 'istighfar',
    title: 'Istighfar',
    arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
    transliteration: 'Astaghfirullahal \'azhim',
    meaning: 'Aku memohon ampun kepada Allah Yang Mahaagung',
    defaultTarget: 33,
    sourceRef: 'HR. Muslim no. 2702 (anjuran memperbanyak istighfar)',
  ),
  TasbihPreset(
    id: 'shalawat',
    title: 'Shalawat',
    arabic: 'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    transliteration: 'Allahumma shalli \'ala Muhammad wa \'ala ali Muhammad',
    meaning: 'Ya Allah, limpahkanlah shalawat kepada Nabi Muhammad dan keluarga beliau',
    defaultTarget: 33,
    sourceRef: 'HR. Al-Bukhari no. 3370 dan Muslim no. 406',
  ),
  TasbihPreset(
    id: 'bebas',
    title: 'Dzikir bebas',
    arabic: 'ذِكْرُ اللَّهِ',
    transliteration: 'Dzikir pilihan mandiri',
    meaning: 'Hitung bacaan dzikir sesuai kebutuhan Anda',
    defaultTarget: 33,
    sourceRef: 'Pilihan bebas',
  ),
];

TasbihPreset findTasbihPreset(String id) => tasbihPresets.firstWhere(
  (preset) => preset.id == id,
  orElse: () => tasbihPresets.first,
);

class TasbihState {
  const TasbihState({
    this.presetId = 'subhanallah',
    this.count = 0,
    this.target = 33,
    this.completedRounds = 0,
    this.totalCount = 0,
    this.hapticEnabled = true,
  });

  static const int minTarget = 1;
  static const int maxTarget = 9999;

  final String presetId;
  final int count;
  final int target;
  final int completedRounds;
  final int totalCount;
  final bool hapticEnabled;

  TasbihPreset get preset => findTasbihPreset(presetId);

  double get progress => target <= 0 ? 0 : (count / target).clamp(0.0, 1.0);

  bool get isTargetReached => count >= target && target > 0;

  (TasbihState next, bool reachedTarget) increment() {
    final nextCount = count >= target ? 1 : count + 1;
    final reached = nextCount == target;
    return (
      copyWith(
        count: nextCount,
        completedRounds: completedRounds + (reached ? 1 : 0),
        totalCount: totalCount + 1,
      ),
      reached,
    );
  }

  TasbihState decrement() {
    if (totalCount <= 0) return this;
    if (count == target && completedRounds > 0) {
      return copyWith(
        count: count - 1,
        completedRounds: completedRounds - 1,
        totalCount: totalCount - 1,
      );
    }
    if (count == 1 && completedRounds > 0) {
      return copyWith(count: target, totalCount: totalCount - 1);
    }
    if (count > 0) {
      return copyWith(count: count - 1, totalCount: totalCount - 1);
    }
    return this;
  }

  TasbihState withTarget(int newTarget) {
    final clamped = newTarget.clamp(minTarget, maxTarget);
    return copyWith(
      target: clamped,
      count: count > clamped ? clamped : count,
    );
  }

  TasbihState copyWith({
    String? presetId,
    int? count,
    int? target,
    int? completedRounds,
    int? totalCount,
    bool? hapticEnabled,
  }) => TasbihState(
    presetId: presetId ?? this.presetId,
    count: count ?? this.count,
    target: target ?? this.target,
    completedRounds: completedRounds ?? this.completedRounds,
    totalCount: totalCount ?? this.totalCount,
    hapticEnabled: hapticEnabled ?? this.hapticEnabled,
  );

  Map<String, dynamic> toJson() => {
    'preset_id': presetId,
    'count': count,
    'target': target,
    'completed_rounds': completedRounds,
    'total_count': totalCount,
    'haptic_enabled': hapticEnabled,
  };

  factory TasbihState.fromJson(Map<String, dynamic> json) {
    final rawTarget = json['target'] is int ? json['target'] as int : 33;
    final safeTarget = rawTarget.clamp(minTarget, maxTarget);
    final rawCount = json['count'] is int ? json['count'] as int : 0;
    final rawRounds = json['completed_rounds'] is int
        ? json['completed_rounds'] as int
        : 0;
    final rawTotal = json['total_count'] is int
        ? json['total_count'] as int
        : 0;
    final rawPresetId = json['preset_id'] is String
        ? json['preset_id'] as String
        : tasbihPresets.first.id;
    return TasbihState(
      presetId: findTasbihPreset(rawPresetId).id,
      count: rawCount.clamp(0, safeTarget),
      target: safeTarget,
      completedRounds: rawRounds < 0 ? 0 : rawRounds,
      totalCount: rawTotal < 0 ? 0 : rawTotal,
      hapticEnabled: json['haptic_enabled'] is bool
          ? json['haptic_enabled'] as bool
          : true,
    );
  }
}
