import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../../../core/database/app_database.dart';
import '../domain/kajian_models.dart';

class CachedKajianFeed {
  const CachedKajianFeed({
    required this.feedUrl,
    required this.source,
    required this.items,
    required this.fetchedAt,
  });

  final String feedUrl;
  final KajianSource source;
  final List<KajianItem> items;
  final DateTime fetchedAt;
}

abstract interface class KajianCacheStore {
  Future<void> saveFeed(CachedKajianFeed feed);
  Future<CachedKajianFeed?> getFeed(String feedUrl);
  Future<void> deleteFeed(String feedUrl);
}

class SqliteKajianCacheStore implements KajianCacheStore {
  const SqliteKajianCacheStore(this._appDatabase);

  final AppDatabase _appDatabase;

  Future<Database> get _database => _appDatabase.database;

  @override
  Future<void> saveFeed(CachedKajianFeed feed) async {
    final db = await _database;
    await db.insert(
      'kajian_catalog_cache',
      {
        'feed_url': feed.feedUrl,
        'source_json': jsonEncode(feed.source.toJson()),
        'items_json': jsonEncode(
          feed.items.map((item) => item.toJson()).toList(growable: false),
        ),
        'fetched_at': feed.fetchedAt.toUtc().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<CachedKajianFeed?> getFeed(String feedUrl) async {
    final db = await _database;
    final rows = await db.query(
      'kajian_catalog_cache',
      where: 'feed_url = ?',
      whereArgs: [feedUrl],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    final sourceMap =
        jsonDecode(row['source_json']! as String) as Map<String, dynamic>;
    final rawItems = jsonDecode(row['items_json']! as String) as List<dynamic>;
    final fetchedAt =
        DateTime.tryParse(row['fetched_at']! as String) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return CachedKajianFeed(
      feedUrl: row['feed_url']! as String,
      source: KajianSource.fromJson(sourceMap.cast<String, Object?>()),
      items: rawItems
          .map(
            (entry) => KajianItem.fromJson(
              (entry as Map<String, dynamic>).cast<String, Object?>(),
            ),
          )
          .toList(growable: false),
      fetchedAt: fetchedAt,
    );
  }

  @override
  Future<void> deleteFeed(String feedUrl) async {
    final db = await _database;
    await db.delete(
      'kajian_catalog_cache',
      where: 'feed_url = ?',
      whereArgs: [feedUrl],
    );
  }
}
