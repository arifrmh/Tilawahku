class IslamicQuote {
  const IslamicQuote({
    required this.id,
    required this.category,
    required this.textId,
    required this.author,
    required this.sourceRef,
    this.textAr,
  });

  final String id;
  final String category;
  final String? textAr;
  final String textId;
  final String author;
  final String sourceRef;

  String get copyText {
    final buffer = StringBuffer();
    if (textAr != null && textAr!.trim().isNotEmpty) {
      buffer.writeln(textAr!.trim());
      buffer.writeln();
    }
    buffer.writeln('"$textId"');
    buffer.write('$author ($sourceRef)');
    return buffer.toString();
  }

  factory IslamicQuote.fromJson(Map<String, dynamic> json) => IslamicQuote(
    id: json['id'] as String,
    category: json['category'] as String,
    textAr: json['text_ar'] as String?,
    textId: json['text_id'] as String,
    author: json['author'] as String,
    sourceRef: json['source_ref'] as String,
  );
}

class IslamicStory {
  const IslamicStory({
    required this.id,
    required this.title,
    required this.category,
    required this.readMinutes,
    required this.summary,
    required this.paragraphs,
    required this.lessons,
    required this.sourceRef,
  });

  final String id;
  final String title;
  final String category;
  final int readMinutes;
  final String summary;
  final List<String> paragraphs;
  final List<String> lessons;
  final String sourceRef;

  String get copyText {
    final lessonLines = lessons.map((item) => '- $item').join('\n');
    return '$title ($category)\n\n$summary\n\nPelajaran (Ibrah):\n$lessonLines\n\nSumber: $sourceRef';
  }

  factory IslamicStory.fromJson(Map<String, dynamic> json) => IslamicStory(
    id: json['id'] as String,
    title: json['title'] as String,
    category: json['category'] as String,
    readMinutes: json['read_minutes'] as int,
    summary: json['summary'] as String,
    paragraphs: (json['paragraphs'] as List<dynamic>)
        .map((item) => item as String)
        .toList(growable: false),
    lessons: (json['lessons'] as List<dynamic>)
        .map((item) => item as String)
        .toList(growable: false),
    sourceRef: json['source_ref'] as String,
  );
}

/// Memilih kutipan harian secara deterministik berdasarkan tanggal lokal tanpa
/// memerlukan server.
IslamicQuote? quoteOfTheDay(List<IslamicQuote> quotes, DateTime date) {
  if (quotes.isEmpty) return null;
  final dayIndex = DateTime.utc(date.year, date.month, date.day)
      .difference(DateTime.utc(2026, 1, 1))
      .inDays;
  final index = dayIndex % quotes.length;
  return quotes[index < 0 ? index + quotes.length : index];
}

List<IslamicQuote> filterQuotes(
  List<IslamicQuote> quotes, {
  required String query,
  required String? category,
  required bool favoritesOnly,
  required Set<String> favorites,
}) {
  final q = query.trim().toLowerCase();
  return quotes
      .where((item) {
        if (favoritesOnly && !favorites.contains(item.id)) return false;
        if (category != null && item.category != category) return false;
        if (q.isEmpty) return true;
        return item.textId.toLowerCase().contains(q) ||
            item.author.toLowerCase().contains(q) ||
            item.sourceRef.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q);
      })
      .toList(growable: false);
}

List<IslamicStory> filterStories(
  List<IslamicStory> stories, {
  required String query,
  required String? category,
  required bool favoritesOnly,
  required Set<String> favorites,
}) {
  final q = query.trim().toLowerCase();
  return stories
      .where((item) {
        if (favoritesOnly && !favorites.contains(item.id)) return false;
        if (category != null && item.category != category) return false;
        if (q.isEmpty) return true;
        return item.title.toLowerCase().contains(q) ||
            item.summary.toLowerCase().contains(q) ||
            item.sourceRef.toLowerCase().contains(q) ||
            item.category.toLowerCase().contains(q);
      })
      .toList(growable: false);
}
