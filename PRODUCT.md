# Product

<!-- impeccable:product-schema 1 -->

## Platform

android

## Users

- **Primary users:** Indonesian Muslims across households, students, and Qur'an memorizers (parents, children 5-12 accompanied by adults, and independent adult learners/memorizers) using Android devices, including mid-range and entry-level hardware, often in low-connectivity or offline environments.
- **Core jobs:** Read the 30-juz Qur'an cleanly without ads or distractions; listen to and repeat murottal offline; run structured memorization programs with local AI voice recitation checks; learn Tajwid fundamentals; and rely on daily worship tools (prayer times, Qibla, Hijri calendar) and verified Islamic references on the Lainnya tab.

## Product Purpose

TILAWAHKU exists to provide a calm, ad-free, offline-first Qur'an and daily Islamic companion app where reading, audio repetition, memorization practice, and worship essentials live in one trustworthy Android app without requiring accounts, subscriptions, or constant internet access.

Success means:
- Core text, translation, transliteration, memorization progress, Tajwid lessons, Qibla bearing, and upcoming Islamic text references work reliably offline.
- Every religious text, citation, translation, and audio source is transparently attributed and verified rather than fabricated.
- Both light and dark themes, accessibility scaling, and device-level worship features (prayer notifications, compass, microphone ASR) hold up on real Android hardware.

## Positioning

Unlike ad-supported or cloud-dependent Qur'an apps, TILAWAHKU combines bundled 30-juz offline Qur'an data, flexible per-ayah/range repetition across multiple reciters, on-device Arabic speech recognition (sherpa-onnx Zipformer CTC) for memorization checks, and offline-first worship tools in an open-source (GPL-3.0), zero-account, zero-ad Android experience.

## Operating Context

- **Navigation structure:** 4-tab Material 3 app (`Beranda`, `Al-Qur'an`, `Aktivitas`, `Lainnya`).
- **Distribution & target platforms:** Android is the primary production target (Material 3). Flutter Web serves only as a limited preview (no local audio playback/downloads, no notifications, manual Qibla dial). iOS support is deferred for a future release.
- **Local-first data:** SQLite (`DatabaseSchema` v9) and `SharedPreferences` hold all reading progress, bookmarks, memorization programs/history, Tajwid quiz attempts, and cached prayer/Hijri schedules. No user accounts or cloud sync exist.
- **Language:** Indonesian (`id`) primary UI copy paired with Arabic (`ar`, RTL) for Qur'anic scripture, Hijri labels, and Islamic terminology.

## Capabilities and Constraints

### Confirmed live capabilities
- **Al-Qur'an reader:** 114 surahs, 30 juz, 6,236 ayahs (`quran-uthmani`), Latin transliteration (`en.transliteration`), Indonesian translation (`id.indonesian`), surah/juz/page navigation, search, bookmarks, last-read progress, adjustable Arabic text scale.
- **Audio, repeat, and offline downloads:** 10 reciters configured via `assets/config/suara.json` (9 per-ayah downloadable reciters + 1 per-surah streaming reciter `ar.muhammadalluhaidan`), background playback (`just_audio` + `audio_service`), repeat modes, playback speed, sleep timer, per-juz and per-surah download manager.
- **Memorization & AI recitation check:** Memorization programs (surah/juz/range), daily targets, practice modes (`learn`, `hide_reveal`, `recall`, `audio_repetition`, `ai_assessment` via `sherpa_onnx` + `record`), status history.
- **Belajar Tajwid:** Offline Tajwid lesson catalog and quiz practice with local attempt history.
- **Lainnya tab (active):** Waktu salat (AlAdhan API v1 + SQLite cache + 37-city catalog + GPS + local reminders), Arah kiblat (offline great-circle bearing + device compass + manual dial), Kalender Hijriah (monthly view + Islamic events + day adjustment).

### Planned capabilities (confirmed roadmap)
- **Lainnya tab (priority next):** `Asmaul Husna` (100% offline), `Quotes dan kisah Islam` (100% offline), `Tokoh Islam` (100% offline), `Kajian dan ceramah` (curated streaming from officially licensed/authorized audio feeds, with local metadata cache).
- **Aktivitas tab (later backlog):** `Statistik membaca`, `Tasbih digital`, `Doa dan dzikir`.

### Binding product constraints
- **Free forever, zero ads, zero accounts:** No paywalls, ads, user login, or cloud tracking.
- **Offline text guarantee:** All text-based features (Qur'an, Tajwid, Asmaul Husna, Tokoh Islam, Quotes & Kisah Islam) must be bundled locally and work 100% offline.
- **Streaming honesty:** Kajian dan ceramah may stream only from officially licensed or explicitly authorized sources (no unauthorized scraping), with clear offline/network messaging.
- **Religious accuracy:** Qur'anic text must never be altered or mixed with non-Qur'anic text; prayer times and Hijri dates are presented honestly as calculated estimates, not official government/rukyat declarations; AI recitation checks assess word matching only, never claiming to evaluate Tajwid or makhraj.
- **Licensing:** Application source code is GNU GPL-3.0 (`LICENSE`). Third-party content remains under its own license/terms.

### Deliberately open decisions
- Hosting URL for the Android ASR ONNX model (`ASR_MODEL_BASE_URL`, `model.int8.onnx`) is not yet finalized.
- Official written redistribution verification for `id.indonesian` (Kemenag match) and `ar.muhammadalluhaidan` audio remains open prior to public Play Store distribution.
- Specific authorized audio/RSS sources for `Kajian dan ceramah` have not yet been selected.
- Production Android `applicationId` (currently `com.example.tilawahku`) and release signing keystore are not yet configured.
- Real Android hardware verification for prayer reminders, live Qibla compass, and microphone ASR has not yet been completed.

## Brand Commitments

- **Name & app mark:** `TILAWAHKU` with existing bundled app icon (`assets/branding/tilawahku_icon.png`).
- **Voice & tone:** Calm, respectful, plain Indonesian without marketing hype or fabricated claims; honest about platform/offline limitations.
- **Scripture typeface:** `AmiriQuran` (`assets/fonts/AmiriQuran-Regular.ttf`, SIL OFL 1.1) for Arabic scripture.

## Evidence on Hand

- `assets/data/tilawahku_content.db` & `assets/data/quran_web_preview.json`: Full 114-surah, 6,236-ayah Qur'an database (AlQuran.cloud `quran-uthmani`, `id.indonesian`, `en.transliteration`).
- `assets/config/suara.json`: 10-reciter audio catalog and edition metadata.
- `assets/prayer/city_locations.json`: 37 Indonesian/regional city coordinates (OpenStreetMap Nominatim, ODbL 1.0) and timezones.
- `assets/fonts/AmiriQuran-Regular.ttf` & `assets/fonts/OFL.txt`: Bundled Arabic Qur'an font and license.
- `web/asr/tokens.txt` & `web/asr/LICENSE`: `Abdou/quran-asr-small` (MIT) metadata and checksum contract (`lib/features/assessment/data/asr_model_release.dart`); binary `model.int8.onnx` (36 MB) is intentionally excluded from Git.
- `docs/PRD.md`, `docs/Scope.md`, `docs/Design.md`, `docs/Task.md`, `docs/prd-06-prayer-times.md`, `docs/prd-07-qibla.md`: Maintained product, scope, design, roadmap, and implementation notes.
- **Known absences (never fabricate):** No user testimonials, no usage/download statistics, no verified female/child reciter recordings, no verified automated color-coded Tajwid verse annotation dataset, and no authorized Kajian feed list yet.

## Product Principles

1. **Offline dependability first:** Reading, memorization, Tajwid, Qibla bearing, and Islamic text references must remain usable without signal.
2. **Honesty over polish:** Never fake data, hide platform limits, overstate AI assessment scope, or present calculated dates/times as official religious rulings.
3. **Zero-distraction worship:** Keep every screen calm, ad-free, account-free, and focused on the user's immediate act of reading, memorizing, or learning.
4. **Verified provenance:** Every religious text, narration, biography, quote, and audio stream carries an explicit, verifiable source and license record.
5. **Native Android ergonomics:** Honor Material 3 conventions, reliable light and dark themes, readable Arabic typography, and accessible touch targets across real Android devices.

## Accessibility & Inclusion

- Minimum 48x48 dp touch targets with clear spacing across controls (supporting children, older adults, and one-handed mobile use).
- Adjustable Arabic text scaling (`arabicTextScale`) and support for system font scaling without clipping or overlapping text.
- WCAG AA contrast in both light and dark themes across all screens, with generous Arabic line height so diacritics (harakat) never clip.
- Explicit RTL handling (`TextDirection.rtl`) for Arabic scripture and labels within Indonesian LTR screens.
- Optional hardware sensors (compass, microphone, GPS) always have manual/non-blocking fallbacks so devices without those sensors remain usable.
