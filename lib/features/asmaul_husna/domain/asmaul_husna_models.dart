class AsmaulHusnaAyahRef {
  const AsmaulHusnaAyahRef({required this.surah, required this.ayah});

  final int surah;
  final int ayah;

  String get label => 'QS $surah:$ayah';

  factory AsmaulHusnaAyahRef.fromJson(Map<String, dynamic> json) =>
      AsmaulHusnaAyahRef(
        surah: json['surah'] as int,
        ayah: json['ayah'] as int,
      );
}

class AsmaulHusnaEntry {
  const AsmaulHusnaEntry({
    required this.number,
    required this.arabic,
    required this.transliteration,
    required this.meaningId,
    required this.descriptionId,
    required this.quranRefs,
  });

  final int number;
  final String arabic;
  final String transliteration;
  final String meaningId;
  final String descriptionId;
  final List<AsmaulHusnaAyahRef> quranRefs;

  String get copyText {
    final refs = quranRefs.isEmpty
        ? ''
        : '\nRujukan: ${quranRefs.map((ref) => ref.label).join(', ')}';
    return '$number. $arabic ($transliteration)\n$meaningId\n$descriptionId$refs';
  }

  factory AsmaulHusnaEntry.fromJson(Map<String, dynamic> json) =>
      AsmaulHusnaEntry(
        number: json['number'] as int,
        arabic: json['arabic'] as String,
        transliteration: json['transliteration'] as String,
        meaningId: json['meaning_id'] as String,
        descriptionId: json['description_id'] as String,
        quranRefs: ((json['quran_refs'] as List<dynamic>?) ?? const [])
            .map(
              (item) =>
                  AsmaulHusnaAyahRef.fromJson(item as Map<String, dynamic>),
            )
            .toList(growable: false),
      );
}

String _normalizeSearch(String value) => value
    .toLowerCase()
    .replaceAll(RegExp(r"[-'\s`’]+"), '')
    .trim();

List<AsmaulHusnaEntry> filterAsmaulHusna(
  List<AsmaulHusnaEntry> entries, {
  required String query,
  required bool favoritesOnly,
  required Set<int> favorites,
}) {
  final rawQuery = query.trim().toLowerCase();
  final normalizedQuery = _normalizeSearch(query);

  return entries
      .where((entry) {
        if (favoritesOnly && !favorites.contains(entry.number)) {
          return false;
        }
        if (rawQuery.isEmpty) return true;
        if ('${entry.number}' == rawQuery) return true;
        if (entry.arabic.contains(query.trim())) return true;
        if (entry.transliteration.toLowerCase().contains(rawQuery)) return true;
        if (entry.meaningId.toLowerCase().contains(rawQuery)) return true;
        if (normalizedQuery.isNotEmpty &&
            _normalizeSearch(entry.transliteration).contains(normalizedQuery)) {
          return true;
        }
        return false;
      })
      .toList(growable: false);
}
