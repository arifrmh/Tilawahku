# TILAWAHKU

TILAWAHKU is an offline-first Qur'an reader, memorization companion, and daily Islamic ibadah app built with Flutter. Qur'an text, Indonesian translation, transliteration, and Islamic reference content are bundled locally; reciter audio is streamed or downloaded per juz/surah on demand and stored on the device.

## Project structure

- `lib/app/`: application bootstrap and centralized light/dark themes.
- `lib/core/database/`: SQLite schema (v10), migrations, and bundled content seeding.
- `lib/core/preferences/`: onboarding and local preferences.
- `lib/features/navigation/`: bottom navigation shell (Beranda, Al-Qur'an, Aktivitas, Lainnya).
- `lib/features/reading/`: surah/juz/page Mushaf reader, search, scroll-saved progress, and bookmarks.
- `lib/features/voices/`: reciter catalog, portraits/monogram avatars, and audio preview selection.
- `lib/features/player/` & `lib/features/repeat/`: local/streaming playback, background controls, and ayah/range/surah/juz repeat.
- `lib/features/download/`: per-juz and per-surah offline audio download manager.
- `lib/features/memorization/`: memorization programs, practice modes, and daily progress tracking.
- `lib/features/assessment/`: on-device recitation checking (`sherpa-onnx` + `Abdou/quran-asr-small`) with word-level Arabic highlights.
- `lib/features/tajwid/`: interactive Tajwid lessons and quizzes.
- `lib/features/prayer/`, `lib/features/qibla/`, `lib/features/hijri/`: prayer schedules (AlAdhan API + local cache), reminders, local Qibla compass/manual dial, and Hijri calendar.
- `lib/features/asmaul_husna/`, `lib/features/doa_dzikir/`, `lib/features/tasbih/`, `lib/features/islamic_figures/`, `lib/features/quotes_stories/`, `lib/features/reading_stats/`: offline daily ibadah tools, Islamic knowledge, and reading statistics.
- `lib/features/kajian/`: ready-to-use Islamic lecture podcast streaming with local SQLite catalog cache.
- `lib/features/settings/` & `lib/features/about/`: display/audio settings and app attribution.
- `assets/config/suara.json` & `assets/voices/`: reciter catalogue and open-licensed Wikimedia Commons portraits.
- `assets/data/tilawahku_content.db`: bundled Qur'an text, translation, transliteration, and audio manifests.
- `assets/islamic/`: bundled offline Asmaul Husna, doa & dzikir, quotes, stories, and Islamic figures datasets.
- `assets/fonts/`: Amiri Quran font and its SIL Open Font License.
- `docs/`: product requirements, scope, design, roadmap tasks, and feature notes (see [docs/README.md](docs/README.md)).
- `tools/build_quran_database.py`: offline-database build/import script.

## Bundled content and provenance

The checked-in database contains 114 surahs and 6,236 ayahs with the `quran-uthmani` Arabic edition, `id.indonesian` translation, and `en.transliteration` transliteration from AlQuran.cloud. `assets/config/suara.json` defines 9 active per-ayah reciters (Husary, Minshawi, Alafasy, Abdul Basit, As-Sudais, Hani Rifai, Maher Al Muaiqly, Muhammad Ayyoub, and Saood Ash-Shuraym) whose 30-juz audio manifests are seeded locally in SQLite on startup, plus 1 surah-based streaming reciter (Muhammad al-Luhaidan, `ar.muhammadalluhaidan`, 128 kbps MP3 via Islamic Network CDN). MP3 files are not bundled in the APK.

The `id.indonesian` API edition metadata identifies its translator as `Unknown`. Confirm exact Kemenag edition alignment and redistribution permissions before public distribution. Recording-specific redistribution permission for Muhammad al-Luhaidan is likewise unverified; confirm before distributing audio.

Selected reciter portraits in `assets/voices/` are sourced from Wikimedia Commons under open licenses (Public Domain, CC BY-SA 3.0/4.0, GODL-India, Copyrighted free use); reciters without a verified solo portrait use a monogram avatar.

The Arabic reader uses Amiri Quran from Google Fonts under the SIL Open Font License 1.1 (`assets/fonts/OFL.txt`). Prayer times and Hijri dates are fetched from AlAdhan API v1 (`api.aladhan.com`) with city coordinates from OpenStreetMap Nominatim (ODbL 1.0); Qibla bearing is computed locally via great-circle formulas. Kajian dan ceramah loads built-in public RSS 2.0 podcast feeds (Anchor / Spotify for Podcasters) and caches metadata locally.

Rebuild the bundled database after reviewing source editions and permissions:

```shell
python tools/build_quran_database.py
```

## Run and verify

```shell
flutter pub get
flutter run
flutter analyze
flutter test
```

Background audio uses `just_audio` and `audio_service`. The Android activity and manifest are configured for background playback and system media controls.

## Flutter Web preview

The browser preview uses `sqflite_common_ffi_web` (IndexedDB). After `flutter pub get`, install its WebAssembly and worker files into `web/`:

```shell
dart run sqflite_common_ffi_web:setup
flutter run -d chrome
```

Web preview initializes from `assets/data/quran_web_preview.json` (generated with `python tools/build_quran_web_preview.py`). Audio playback and offline audio downloads are disabled in Web preview.

## Current operational limitations

- Qur'an text, translation, transliteration, bookmarks, memorization, tajwid, and `assets/islamic/` content work fully offline.
- Per-ayah reciter audio works offline once downloaded by juz or surah; deleting one grouping removes overlapping ayah files from the other.
- On-device recitation checking requires a one-time download of the `Abdou/quran-asr-small` ONNX model; it checks word-level match and does not grade tajwid or makhraj.
- Prayer schedules, Hijri calendar updates, and Kajian audio streaming require internet access (cached metadata remains readable offline).
- Remote voice revocation and verification of the exact Kemenag translation edition remain outstanding.

## License

Copyright (C) 2026 Arif Rahmaanul Hakim and TILAWAHKU contributors.

The source code of TILAWAHKU is licensed under the **GNU General Public License v3.0 (GPL-3.0)** (see [LICENSE](LICENSE)).

### Third-party assets and content

The GPL-3.0 license applies only to the TILAWAHKU application source code. Bundled and streamed third-party assets remain subject to their respective licenses and source terms:

- **Amiri Quran font** (`assets/fonts/`): SIL Open Font License 1.1 ([assets/fonts/OFL.txt](assets/fonts/OFL.txt)).
- **Reciter portraits** (`assets/voices/`): Wikimedia Commons open-licensed portraits (see `assets/config/suara.json` attribution fields).
- **ASR model metadata/assets** (`web/asr/`, on-device download): `Abdou/quran-asr-small`, MIT License ([web/asr/LICENSE](web/asr/LICENSE)).
- **Qur'an text, translation, transliteration, audio streams, prayer/Hijri APIs, and public podcast feeds**: subject to each provider's terms and attribution requirements described in [Bundled content and provenance](#bundled-content-and-provenance).
