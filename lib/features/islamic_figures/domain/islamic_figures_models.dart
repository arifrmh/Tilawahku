enum FigureCategory {
  nabiRasul('nabi_rasul', 'Nabi & Rasul'),
  sahabat('sahabat', 'Sahabat'),
  ulamaImam('ulama_imam', 'Ulama & Imam'),
  ilmuwan('ilmuwan', 'Ilmuwan Muslim'),
  nusantara('nusantara', 'Tokoh Nusantara');

  const FigureCategory(this.id, this.label);

  final String id;
  final String label;

  static FigureCategory fromId(String value) => values.firstWhere(
    (category) => category.id == value,
    orElse: () => throw FormatException('Kategori tokoh tidak dikenal: $value'),
  );
}

class BiographySection {
  const BiographySection({required this.title, required this.body});

  final String title;
  final String body;

  factory BiographySection.fromJson(Map<String, dynamic> json) =>
      BiographySection(
        title: (json['title'] as String).trim(),
        body: (json['body'] as String).trim(),
      );
}

class IslamicFigure {
  const IslamicFigure({
    required this.id,
    required this.name,
    required this.arabicName,
    required this.epithet,
    required this.category,
    required this.eraLabel,
    required this.summary,
    required this.biographySections,
    required this.keyLessons,
    required this.references,
    this.dateNote,
  });

  final String id;
  final String name;
  final String arabicName;
  final String epithet;
  final FigureCategory category;
  final String eraLabel;
  final String? dateNote;
  final String summary;
  final List<BiographySection> biographySections;
  final List<String> keyLessons;
  final List<String> references;

  String get monogram {
    const ignored = {'nabi', 'imam', 'kh.', 'kh', 'sunan', 'abu', 'ibnu', 'al'};
    final words = name
        .split(RegExp(r'[\s\-]+'))
        .map((w) => w.replaceAll(RegExp(r"[^A-Za-z.]"), ''))
        .where((w) => w.isNotEmpty)
        .toList();
    final primary = words
        .where((w) => !ignored.contains(w.toLowerCase()))
        .toList();
    final source = primary.isNotEmpty ? primary : words;
    if (source.isEmpty) return 'T';
    if (source.length == 1) {
      return source.first.substring(0, source.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${source[0][0]}${source[1][0]}'.toUpperCase();
  }

  factory IslamicFigure.fromJson(Map<String, dynamic> json) => IslamicFigure(
    id: (json['id'] as String).trim(),
    name: (json['name'] as String).trim(),
    arabicName: (json['arabic_name'] as String).trim(),
    epithet: (json['epithet'] as String).trim(),
    category: FigureCategory.fromId((json['category'] as String).trim()),
    eraLabel: (json['era_label'] as String).trim(),
    dateNote: (json['date_note'] as String?)?.trim(),
    summary: (json['summary'] as String).trim(),
    biographySections: (json['biography_sections'] as List<dynamic>)
        .map((item) => BiographySection.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
    keyLessons: (json['key_lessons'] as List<dynamic>)
        .map((item) => (item as String).trim())
        .toList(growable: false),
    references: (json['references'] as List<dynamic>)
        .map((item) => (item as String).trim())
        .toList(growable: false),
  );
}

List<IslamicFigure> filterIslamicFigures(
  List<IslamicFigure> items, {
  FigureCategory? category,
  String query = '',
  Set<String>? favoriteIds,
}) {
  final needle = query.trim().toLowerCase();
  return items
      .where((item) {
        if (category != null && item.category != category) return false;
        if (favoriteIds != null && !favoriteIds.contains(item.id)) return false;
        if (needle.isEmpty) return true;
        return item.name.toLowerCase().contains(needle) ||
            item.arabicName.toLowerCase().contains(needle) ||
            item.epithet.toLowerCase().contains(needle) ||
            item.eraLabel.toLowerCase().contains(needle) ||
            item.summary.toLowerCase().contains(needle);
      })
      .toList(growable: false);
}
