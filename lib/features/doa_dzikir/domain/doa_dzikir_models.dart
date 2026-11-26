enum DoaDzikirCategory {
  harian('harian', 'Doa Harian'),
  pagi('pagi', 'Dzikir Pagi'),
  petang('petang', 'Dzikir Petang');

  const DoaDzikirCategory(this.id, this.label);

  final String id;
  final String label;

  static DoaDzikirCategory fromId(String value) => values.firstWhere(
    (category) => category.id == value,
    orElse: () =>
        throw FormatException('Kategori doa/dzikir tidak dikenal: $value'),
  );
}

class DoaDzikirEntry {
  const DoaDzikirEntry({
    required this.id,
    required this.category,
    required this.title,
    required this.arabic,
    required this.transliteration,
    required this.translationId,
    required this.repeatCount,
    required this.sourceRef,
    this.notes,
  });

  final String id;
  final DoaDzikirCategory category;
  final String title;
  final String arabic;
  final String transliteration;
  final String translationId;
  final int repeatCount;
  final String sourceRef;
  final String? notes;

  factory DoaDzikirEntry.fromJson(Map<String, dynamic> json) => DoaDzikirEntry(
    id: (json['id'] as String).trim(),
    category: DoaDzikirCategory.fromId((json['category'] as String).trim()),
    title: (json['title'] as String).trim(),
    arabic: (json['arabic'] as String).trim(),
    transliteration: (json['transliteration'] as String).trim(),
    translationId: (json['translation_id'] as String).trim(),
    repeatCount: (json['repeat_count'] as int?) ?? 1,
    sourceRef: (json['source_ref'] as String).trim(),
    notes: (json['notes'] as String?)?.trim(),
  );
}

List<DoaDzikirEntry> filterDoaDzikir(
  List<DoaDzikirEntry> items, {
  DoaDzikirCategory? category,
  String query = '',
  Set<String>? favoriteIds,
}) {
  final needle = query.trim().toLowerCase();
  return items
      .where((item) {
        if (category != null && item.category != category) return false;
        if (favoriteIds != null && !favoriteIds.contains(item.id)) return false;
        if (needle.isEmpty) return true;
        return item.title.toLowerCase().contains(needle) ||
            item.transliteration.toLowerCase().contains(needle) ||
            item.translationId.toLowerCase().contains(needle) ||
            item.sourceRef.toLowerCase().contains(needle);
      })
      .toList(growable: false);
}
