enum KajianCategory {
  alquran('alquran', 'Al-Qur\'an'),
  akidah('akidah', 'Akidah'),
  akhlak('akhlak', 'Akhlak'),
  fiqih('fiqih', 'Fiqih'),
  sirah('sirah', 'Sirah'),
  keluarga('keluarga', 'Keluarga'),
  umum('umum', 'Umum');

  const KajianCategory(this.id, this.label);

  final String id;
  final String label;

  static KajianCategory fromId(String? id) => values.firstWhere(
    (category) => category.id == id,
    orElse: () => KajianCategory.umum,
  );
}

class KajianSource {
  const KajianSource({
    required this.feedUrl,
    required this.title,
    required this.author,
    this.websiteUrl,
    required this.licenseNote,
    this.enabled = true,
    required this.addedAt,
  });

  final String feedUrl;
  final String title;
  final String author;
  final String? websiteUrl;
  final String licenseNote;
  final bool enabled;
  final String addedAt;

  KajianSource copyWith({
    String? title,
    String? author,
    String? websiteUrl,
    String? licenseNote,
    bool? enabled,
  }) => KajianSource(
    feedUrl: feedUrl,
    title: title ?? this.title,
    author: author ?? this.author,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    licenseNote: licenseNote ?? this.licenseNote,
    enabled: enabled ?? this.enabled,
    addedAt: addedAt,
  );

  Map<String, Object?> toJson() => {
    'feed_url': feedUrl,
    'title': title,
    'author': author,
    'website_url': websiteUrl,
    'license_note': licenseNote,
    'enabled': enabled,
    'added_at': addedAt,
  };

  factory KajianSource.fromJson(Map<String, Object?> map) => KajianSource(
    feedUrl: (map['feed_url'] as String? ?? '').trim(),
    title: (map['title'] as String? ?? 'Sumber Kajian').trim(),
    author: (map['author'] as String? ?? 'Pemateri').trim(),
    websiteUrl: (map['website_url'] as String?)?.trim(),
    licenseNote:
        (map['license_note'] as String? ??
                'Feed RSS podcast publik resmi dari penerbit.')
            .trim(),
    enabled: map['enabled'] as bool? ?? true,
    addedAt: (map['added_at'] as String? ?? '').trim(),
  );
}

const List<KajianSource> defaultKajianSources = [
  KajianSource(
    feedUrl: 'https://anchor.fm/s/f01c55c/podcast/rss',
    title: 'Kajian Ustadz Khalid Basalamah',
    author: 'Ustadz Khalid Basalamah',
    websiteUrl: 'https://anchor.fm/s/f01c55c/podcast/rss',
    licenseNote: 'Feed RSS podcast publik melalui Anchor / Spotify for Podcasters.',
    addedAt: '2026-11-26T00:00:00Z',
  ),
  KajianSource(
    feedUrl: 'https://anchor.fm/s/13862884/podcast/rss',
    title: 'Kajian Sejarah Islam',
    author: 'Kajian Islam',
    websiteUrl: 'https://anchor.fm/s/13862884/podcast/rss',
    licenseNote: 'Feed RSS podcast publik melalui Anchor / Spotify for Podcasters.',
    addedAt: '2026-11-26T00:00:00Z',
  ),
  KajianSource(
    feedUrl: 'https://anchor.fm/s/1023d4d4/podcast/rss',
    title: 'Podcast Kajian Islam',
    author: 'Generasi Islam',
    websiteUrl: 'https://anchor.fm/s/1023d4d4/podcast/rss',
    licenseNote: 'Feed RSS podcast publik melalui Anchor / Spotify for Podcasters.',
    addedAt: '2026-11-26T00:00:00Z',
  ),
];

class KajianItem {
  const KajianItem({
    required this.id,
    required this.feedUrl,
    required this.title,
    required this.speaker,
    required this.category,
    required this.description,
    required this.audioUrl,
    required this.sourceTitle,
    this.sourceUrl,
    required this.licenseNote,
    this.durationSeconds,
    this.publishedAt,
  });

  final String id;
  final String feedUrl;
  final String title;
  final String speaker;
  final KajianCategory category;
  final String description;
  final String audioUrl;
  final String sourceTitle;
  final String? sourceUrl;
  final String licenseNote;
  final int? durationSeconds;
  final String? publishedAt;

  String get formattedDuration {
    final seconds = durationSeconds;
    if (seconds == null || seconds <= 0) return 'Durasi tidak tercantum';
    return formatKajianDuration(Duration(seconds: seconds));
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'feed_url': feedUrl,
    'title': title,
    'speaker': speaker,
    'category': category.id,
    'description': description,
    'audio_url': audioUrl,
    'source_title': sourceTitle,
    'source_url': sourceUrl,
    'license_note': licenseNote,
    'duration_seconds': durationSeconds,
    'published_at': publishedAt,
  };

  factory KajianItem.fromJson(Map<String, Object?> map) => KajianItem(
    id: (map['id'] as String? ?? '').trim(),
    feedUrl: (map['feed_url'] as String? ?? '').trim(),
    title: (map['title'] as String? ?? 'Kajian tanpa judul').trim(),
    speaker: (map['speaker'] as String? ?? 'Pemateri').trim(),
    category: KajianCategory.fromId(map['category'] as String?),
    description: (map['description'] as String? ?? '').trim(),
    audioUrl: (map['audio_url'] as String? ?? '').trim(),
    sourceTitle: (map['source_title'] as String? ?? 'Sumber Kajian').trim(),
    sourceUrl: (map['source_url'] as String?)?.trim(),
    licenseNote: (map['license_note'] as String? ?? '').trim(),
    durationSeconds: (map['duration_seconds'] as num?)?.toInt(),
    publishedAt: (map['published_at'] as String?)?.trim(),
  );
}

class KajianPlaybackRecord {
  const KajianPlaybackRecord({
    required this.itemId,
    required this.positionMs,
    required this.durationMs,
    required this.playedAt,
  });

  final String itemId;
  final int positionMs;
  final int durationMs;
  final String playedAt;

  Duration get position => Duration(milliseconds: positionMs);

  double get progressFraction =>
      durationMs <= 0 ? 0 : (positionMs / durationMs).clamp(0.0, 1.0);

  Map<String, Object?> toJson() => {
    'item_id': itemId,
    'position_ms': positionMs,
    'duration_ms': durationMs,
    'played_at': playedAt,
  };

  factory KajianPlaybackRecord.fromJson(Map<String, Object?> map) =>
      KajianPlaybackRecord(
        itemId: (map['item_id'] as String? ?? '').trim(),
        positionMs: (map['position_ms'] as num?)?.toInt() ?? 0,
        durationMs: (map['duration_ms'] as num?)?.toInt() ?? 0,
        playedAt: (map['played_at'] as String? ?? '').trim(),
      );
}

class KajianCatalogSnapshot {
  const KajianCatalogSnapshot({
    required this.sources,
    required this.items,
    required this.fromCache,
    this.fetchedAt,
    this.warnings = const [],
  });

  const KajianCatalogSnapshot.empty()
    : sources = const [],
      items = const [],
      fromCache = false,
      fetchedAt = null,
      warnings = const [];

  final List<KajianSource> sources;
  final List<KajianItem> items;
  final bool fromCache;
  final DateTime? fetchedAt;
  final List<String> warnings;
}

class KajianPlaybackState {
  const KajianPlaybackState({
    this.item,
    this.isPlaying = false,
    this.isBuffering = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.speed = 1.0,
    this.errorMessage,
  });

  final KajianItem? item;
  final bool isPlaying;
  final bool isBuffering;
  final Duration position;
  final Duration duration;
  final double speed;
  final String? errorMessage;

  KajianPlaybackState copyWith({
    KajianItem? item,
    bool clearItem = false,
    bool? isPlaying,
    bool? isBuffering,
    Duration? position,
    Duration? duration,
    double? speed,
    String? errorMessage,
    bool clearError = false,
  }) => KajianPlaybackState(
    item: clearItem ? null : (item ?? this.item),
    isPlaying: isPlaying ?? this.isPlaying,
    isBuffering: isBuffering ?? this.isBuffering,
    position: position ?? this.position,
    duration: duration ?? this.duration,
    speed: speed ?? this.speed,
    errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
  );
}

String? normalizeKajianUrl(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
  final scheme = uri.scheme.toLowerCase();
  if (scheme != 'http' && scheme != 'https') return null;
  if (uri.host.trim().isEmpty) return null;
  return uri.toString();
}

String formatKajianDuration(Duration duration) {
  final totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  final mm = minutes.toString().padLeft(2, '0');
  final ss = seconds.toString().padLeft(2, '0');
  if (hours > 0) {
    final hh = hours.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }
  return '$mm:$ss';
}

int? parseRssDurationSeconds(String? raw) {
  if (raw == null) return null;
  final cleaned = raw.trim();
  if (cleaned.isEmpty) return null;
  final numeric = int.tryParse(cleaned);
  if (numeric != null) return numeric >= 0 ? numeric : null;

  final parts = cleaned.split(':').map((part) => int.tryParse(part.trim())).toList();
  if (parts.any((part) => part == null || part < 0)) return null;
  if (parts.length == 2) {
    return parts[0]! * 60 + parts[1]!;
  }
  if (parts.length == 3) {
    return parts[0]! * 3600 + parts[1]! * 60 + parts[2]!;
  }
  return null;
}

KajianCategory inferKajianCategory({
  String? rawCategory,
  required String title,
  required String description,
}) {
  final haystack = '${rawCategory ?? ''} $title $description'.toLowerCase();
  if (_containsAny(haystack, const ['tafsir', 'tadabbur', 'tajwid', 'quran', 'qur\'an', 'al-qur'])) {
    return KajianCategory.alquran;
  }
  if (_containsAny(haystack, const ['akidah', 'aqidah', 'tauhid', 'iman', 'asmaul husna'])) {
    return KajianCategory.akidah;
  }
  if (_containsAny(haystack, const ['fiqih', 'fikih', 'fiqh', 'ibadah', 'salat', 'shalat', 'puasa', 'zakat', 'haji', 'muamalah'])) {
    return KajianCategory.fiqih;
  }
  if (_containsAny(haystack, const ['sirah', 'sejarah', 'sahabat', 'nabi', 'rasul', 'tabiin'])) {
    return KajianCategory.sirah;
  }
  if (_containsAny(haystack, const ['keluarga', 'parenting', 'anak', 'nikah', 'rumah tangga', 'suami', 'istri'])) {
    return KajianCategory.keluarga;
  }
  if (_containsAny(haystack, const ['akhlak', 'adab', 'hati', 'tazkiyatun', 'sabar', 'syukur', 'ikhlas'])) {
    return KajianCategory.akhlak;
  }
  return KajianCategory.umum;
}

bool _containsAny(String haystack, List<String> keywords) =>
    keywords.any(haystack.contains);

List<KajianItem> filterKajianItems({
  required List<KajianItem> items,
  String query = '',
  KajianCategory? category,
  String? speaker,
  bool favoritesOnly = false,
  Set<String> favoriteIds = const {},
}) {
  final normalizedQuery = query.trim().toLowerCase();
  return items
      .where((item) {
        if (favoritesOnly && !favoriteIds.contains(item.id)) return false;
        if (category != null && item.category != category) return false;
        if (speaker != null && speaker.isNotEmpty && item.speaker != speaker) {
          return false;
        }
        if (normalizedQuery.isEmpty) return true;
        return item.title.toLowerCase().contains(normalizedQuery) ||
            item.speaker.toLowerCase().contains(normalizedQuery) ||
            item.description.toLowerCase().contains(normalizedQuery) ||
            item.sourceTitle.toLowerCase().contains(normalizedQuery) ||
            item.category.label.toLowerCase().contains(normalizedQuery);
      })
      .toList(growable: false);
}

List<String> extractKajianSpeakers(List<KajianItem> items) {
  final speakers = items
      .map((item) => item.speaker.trim())
      .where((speaker) => speaker.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return List.unmodifiable(speakers);
}
