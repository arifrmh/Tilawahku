import 'kajian_models.dart';

class ParsedKajianFeed {
  const ParsedKajianFeed({
    required this.source,
    required this.items,
  });

  final KajianSource source;
  final List<KajianItem> items;
}

ParsedKajianFeed parseKajianRssFeed({
  required String xml,
  required String feedUrl,
  String? customLicenseNote,
  DateTime? addedAt,
  int maxItems = 50,
}) {
  final normalizedFeedUrl = normalizeKajianUrl(feedUrl);
  if (normalizedFeedUrl == null) {
    throw const FormatException('URL feed RSS tidak valid. Gunakan http atau https.');
  }

  final channelMatch = RegExp(
    r'<channel\b[^>]*>([\s\S]*?)</channel>',
    caseSensitive: false,
  ).firstMatch(xml);
  if (channelMatch == null) {
    throw const FormatException(
      'Dokumen bukan format RSS podcast yang valid (elemen <channel> tidak ditemukan).',
    );
  }

  final channelContent = channelMatch.group(1)!;
  final itemPattern = RegExp(
    r'<item\b[^>]*>([\s\S]*?)</item>',
    caseSensitive: false,
  );
  final itemMatches = itemPattern.allMatches(channelContent).toList();
  final channelHeader = channelContent.replaceAll(itemPattern, '');

  final channelTitle = _cleanText(_extractTagValue(channelHeader, 'title')) ??
      Uri.parse(normalizedFeedUrl).host;
  final channelAuthor =
      _cleanText(_extractTagValue(channelHeader, 'itunes:author')) ??
      _cleanText(_extractTagValue(channelHeader, 'author')) ??
      channelTitle;
  final channelLink = normalizeKajianUrl(
    _cleanText(_extractTagValue(channelHeader, 'link')) ?? '',
  );
  final channelCopyright = _cleanText(_extractTagValue(channelHeader, 'copyright'));
  final channelCategory =
      _cleanText(_extractTagValue(channelHeader, 'category')) ??
      _cleanText(_extractAttribute(channelHeader, 'itunes:category', 'text'));

  final effectiveLicense = (customLicenseNote != null &&
          customLicenseNote.trim().isNotEmpty)
      ? customLicenseNote.trim()
      : (channelCopyright != null && channelCopyright.isNotEmpty
            ? channelCopyright
            : 'Feed RSS podcast publik dari $channelTitle.');

  final source = KajianSource(
    feedUrl: normalizedFeedUrl,
    title: channelTitle,
    author: channelAuthor,
    websiteUrl: channelLink,
    licenseNote: effectiveLicense,
    enabled: true,
    addedAt: (addedAt ?? DateTime.now()).toUtc().toIso8601String(),
  );

  final items = <KajianItem>[];
  final seenIds = <String>{};

  for (var i = 0; i < itemMatches.length; i++) {
    if (items.length >= maxItems) break;
    final block = itemMatches[i].group(1)!;
    final audioUrl = _extractAudioEnclosureUrl(block);
    if (audioUrl == null) continue;

    final title = _cleanText(_extractTagValue(block, 'title'));
    if (title == null || title.isEmpty) continue;

    final rawGuid = _cleanText(_extractTagValue(block, 'guid'));
    final rawLink = normalizeKajianUrl(
      _cleanText(_extractTagValue(block, 'link')) ?? '',
    );
    final baseId = (rawGuid != null && rawGuid.isNotEmpty)
        ? '$normalizedFeedUrl::$rawGuid'
        : '$normalizedFeedUrl::$audioUrl';
    if (!seenIds.add(baseId)) continue;

    final speaker =
        _cleanText(_extractTagValue(block, 'itunes:author')) ??
        _cleanText(_extractTagValue(block, 'dc:creator')) ??
        _cleanText(_extractTagValue(block, 'author')) ??
        channelAuthor;
    final description =
        _cleanText(_extractTagValue(block, 'itunes:summary')) ??
        _cleanText(_extractTagValue(block, 'description')) ??
        _cleanText(_extractTagValue(block, 'content:encoded')) ??
        '';
    final durationSeconds = parseRssDurationSeconds(
      _cleanText(_extractTagValue(block, 'itunes:duration')),
    );
    final publishedAt = _cleanText(_extractTagValue(block, 'pubDate'));
    final itemCategoryText =
        _cleanText(_extractTagValue(block, 'category')) ?? channelCategory;

    items.add(
      KajianItem(
        id: baseId,
        feedUrl: normalizedFeedUrl,
        title: title,
        speaker: speaker,
        category: inferKajianCategory(
          rawCategory: itemCategoryText,
          title: title,
          description: description,
        ),
        description: description,
        audioUrl: audioUrl,
        sourceTitle: channelTitle,
        sourceUrl: rawLink ?? channelLink,
        licenseNote: effectiveLicense,
        durationSeconds: durationSeconds,
        publishedAt: publishedAt,
      ),
    );
  }

  if (items.isEmpty) {
    throw const FormatException(
      'Feed RSS tidak memiliki episode audio (<enclosure>) yang dapat diputar.',
    );
  }

  return ParsedKajianFeed(
    source: source,
    items: List.unmodifiable(items),
  );
}

String? _extractTagValue(String xml, String tagName) {
  final escaped = RegExp.escape(tagName);
  final match = RegExp(
    '<$escaped\\b[^>]*>([\\s\\S]*?)</$escaped>',
    caseSensitive: false,
  ).firstMatch(xml);
  return match?.group(1);
}

String? _extractAttribute(String xml, String tagName, String attributeName) {
  final escapedTag = RegExp.escape(tagName);
  final tagMatch = RegExp(
    '<$escapedTag\\b([^>]*)/?>',
    caseSensitive: false,
  ).firstMatch(xml);
  if (tagMatch == null) return null;
  return _readAttribute(tagMatch.group(1) ?? '', attributeName);
}

String? _extractAudioEnclosureUrl(String itemXml) {
  final matches = RegExp(
    r'<enclosure\b([^>]*)/?>',
    caseSensitive: false,
  ).allMatches(itemXml);
  for (final match in matches) {
    final attrs = match.group(1) ?? '';
    final rawUrl = _readAttribute(attrs, 'url');
    if (rawUrl == null) continue;
    final decodedUrl = _decodeEntities(rawUrl).trim();
    final normalized = normalizeKajianUrl(decodedUrl);
    if (normalized == null) continue;

    final type = (_readAttribute(attrs, 'type') ?? '').trim().toLowerCase();
    if (type.startsWith('audio/') || _looksLikeAudioUrl(normalized)) {
      return normalized;
    }
  }
  return null;
}

String? _readAttribute(String attrs, String name) {
  final escaped = RegExp.escape(name);
  final match = RegExp(
    '$escaped\\s*=\\s*(?:"([^"]*)"|\'([^\']*)\')',
    caseSensitive: false,
  ).firstMatch(attrs);
  if (match == null) return null;
  return match.group(1) ?? match.group(2);
}

bool _looksLikeAudioUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.mp3') ||
      path.endsWith('.m4a') ||
      path.endsWith('.ogg') ||
      path.endsWith('.opus') ||
      path.endsWith('.aac') ||
      path.endsWith('.wav');
}

String? _cleanText(String? raw) {
  if (raw == null) return null;
  var text = raw.trim();
  if (text.isEmpty) return null;

  text = text.replaceAllMapped(
    RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>', caseSensitive: false),
    (match) => match.group(1) ?? '',
  );
  // Decode entities once before stripping HTML tags in case descriptions contain escaped HTML.
  text = _decodeEntities(text);
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
  text = _decodeEntities(text);
  text = text
      .split('\n')
      .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
  return text.isEmpty ? null : text;
}

String _decodeEntities(String input) {
  var output = input
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', '\'')
      .replaceAll('&#39;', '\'')
      .replaceAll('&nbsp;', ' ');

  output = output.replaceAllMapped(RegExp(r'&#(\d+);'), (match) {
    final code = int.tryParse(match.group(1)!);
    return code == null ? match.group(0)! : String.fromCharCode(code);
  });
  output = output.replaceAllMapped(
    RegExp(r'&#x([0-9a-fA-F]+);'),
    (match) {
      final code = int.tryParse(match.group(1)!, radix: 16);
      return code == null ? match.group(0)! : String.fromCharCode(code);
    },
  );
  return output;
}
