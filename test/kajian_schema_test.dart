import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tilawahku/core/database/database_schema.dart';

void main() {
  test('versi skema naik menjadi 10 atau lebih dengan tabel kajian_catalog_cache', () {
    expect(DatabaseSchema.version, greaterThanOrEqualTo(10));
    expect(DatabaseSchema.kajianCreateStatements, hasLength(1));
    expect(
      DatabaseSchema.createStatements,
      containsAll(DatabaseSchema.kajianCreateStatements),
    );
    final sql = DatabaseSchema.createKajianCatalogCache.trim();
    expect(sql, startsWith('CREATE TABLE kajian_catalog_cache'));
    expect(sql, contains('feed_url TEXT PRIMARY KEY'));
    expect(sql, contains('source_json TEXT NOT NULL'));
    expect(sql, contains('items_json TEXT NOT NULL'));
    expect(sql, contains('fetched_at TEXT NOT NULL'));
    expect(sql, isNot(contains('DROP')));
    expect(sql, isNot(contains('ALTER')));
  });

  test('native dan web menjalankan blok migrasi v10 yang sama', () {
    for (final path in [
      'lib/core/database/app_database_native.dart',
      'lib/core/database/app_database_web.dart',
    ]) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: '$path hilang');
      final source = file.readAsStringSync();
      expect(source, contains('if (oldVersion < 10)'), reason: '$path tanpa v10');
      expect(
        source,
        contains('DatabaseSchema.kajianCreateStatements'),
        reason: '$path tidak membuat tabel cache kajian',
      );
    }
  });
}
