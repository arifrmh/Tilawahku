# Task — TILAWAHKU

Roadmap dan rincian tugas pengembangan TILAWAHKU (v2.0 · 24 November 2026), diturunkan dari [PRD.md](PRD.md), [Scope.md](Scope.md), dan [Design.md](Design.md).

---

## Status Baseline (Sudah Terimplementasi)

Ringkasan fase yang sudah dikerjakan dan tersedia di codebase saat ini:

- [x] **Al-Qur'an 30 Juz Offline:** database SQLite (`assets/data/tilawahku_content.db`), 114 surah, 6.236 ayat (`quran-uthmani`, `id.indonesian`, `en.transliteration`), font `AmiriQuran` (SIL OFL 1.1), navigasi surah/juz/halaman, bookmark, lanjutkan terakhir, mode terang & gelap.
- [x] **Suara, Pemutar, Mode Ulang & Unduhan:** 10 qari di `assets/config/suara.json`, background audio (`just_audio` + `audio_service`), mode ulang (ayat/rentang/surah/juz), kecepatan putar, timer tidur, manajer unduhan per juz/surah.
- [x] **Hafalan & AI Setoran Suara:** program hafalan, target harian, mode latihan (`learn`, `hide_reveal`, `recall`, `audio_repetition`, `ai_assessment` via `sherpa_onnx` + `Abdou/quran-asr-small`), riwayat hafalan.
- [x] **Belajar Tajwid:** katalog materi hukum tajwid dan latihan kuis dengan skor lokal.
- [x] **Halaman Lainnya — Waktu Salat (PRD 06):** jadwal AlAdhan v1, cache SQLite v7, hitung mundur, katalog 37 kota + GPS, pengingat lokal ([prd-06-prayer-times.md](prd-06-prayer-times.md)).
- [x] **Halaman Lainnya — Arah Kiblat (PRD 07):** rumus bearing lokal, lokasi bersama, kompas perangkat + fallback dial manual ([prd-07-qibla.md](prd-07-qibla.md)).
- [x] **Halaman Lainnya — Kalender Hijriah:** tanggal Hijri, kalender bulanan, event Islam, cache SQLite v9.
- [x] **Lisensi Repositori:** penambahan [LICENSE](../LICENSE) (GNU GPLv3) dan pemisahan lisensi aset pihak ketiga di [README.md](../README.md).

---

## Fase L-1 — Halaman Lainnya: Asmaul Husna

Target: mengaktifkan menu **Asmaul Husna** di `_MoreScreen` (100% offline).

- [x] **Konten & Validasi Data**
  - [x] Susun berkas `assets/islamic/asmaul_husna.json` berisi 99 entri lengkap (`number`, `arabic`, `transliteration`, `meaning_id`, `description_id`, `quran_refs`) plus blok `_meta` (sumber & lisensi).
  - [x] Daftarkan `assets/islamic/asmaul_husna.json` di `pubspec.yaml`.
  - [x] Tulis tes validasi data: tepat 99 entri, nomor unik 1–99, tidak ada teks Arab/Latin/arti kosong, semua `quran_refs` valid terhadap jumlah ayat surah Al-Qur'an.
- [x] **Domain & Data (`lib/features/asmaul_husna/`)**
  - [x] Buat model `AsmaulHusnaEntry` dan fungsi filter/pencarian (`domain/`).
  - [x] Buat `AsmaulHusnaRepository` (pemuatan JSON ter-memoisasi + penyimpanan favorit lokal).
  - [x] Buat `AsmaulHusnaController` untuk state pencarian, filter favorit, dan aksi salin/favorit.
- [x] **Presentasi & Integrasi**
  - [x] Buat `AsmaulHusnaScreen` (daftar 99 nama, pencarian, filter favorit) dan detail sheet (teks `AmiriQuran`, uraian, tautan ke `ReadingScreen`, tombol salin & navigasi prev/next).
  - [x] Hubungkan ke `_MoreScreen` di `main_navigation_screen.dart` (ubah `_UnavailableAction` → `_DashboardAction`).
  - [x] Tambahkan atribusi sumber di halaman `AboutScreen`.
- [x] **Pengujian**
  - [x] Tambah unit test, asset validation test, widget test, dan navigation test (`test/asmaul_husna_test.dart`).

---

## Fase L-2 — Halaman Lainnya: Quotes dan Kisah Islam

Target: mengaktifkan menu **Quotes dan kisah Islam** di `_MoreScreen` (100% offline).

- [x] **Konten & Kurasi Sumber**
  - [x] Susun `assets/islamic/quotes.json` (kutipan hikmah terverifikasi dengan `id`, `text_ar` opsional, `text_id`, `author`, `source_ref`, `category`) + blok `_meta`.
  - [x] Susun `assets/islamic/stories.json` (kisah Islami terverifikasi dengan `id`, `title`, `category`, `read_minutes`, `paragraphs`, `lessons`, `source_ref`) + blok `_meta`.
  - [x] Daftarkan aset di `pubspec.yaml` dan buat tes validasi skema & kelengkapan `source_ref` (tidak ada entri tanpa rujukan).
- [x] **Domain & Data (`lib/features/quotes_stories/`)**
  - [x] Buat model `IslamicQuote`, `IslamicStory`, serta logika filter kategori, pencarian, dan *Quote of the Day* deterministik lokal.
  - [x] Buat repository & penyimpanan favorit lokal (`AppPreferences`).
  - [x] Buat controller untuk state tab *Quotes* dan *Kisah*.
- [x] **Presentasi & Integrasi**
  - [x] Buat `QuotesStoriesScreen` dengan 2 tab (`Quotes` & `Kisah`), filter kategori, pencarian, dan filter favorit.
  - [x] Buat kartu quote bergaya navy-emas dengan aksi **Favorit** dan **Salin** (menyertakan atribusi sumber).
  - [x] Buat `StoryDetailScreen` dengan tata letak baca nyaman, kontrol ukuran huruf (`A-`/`A+`), blok *Pelajaran (Ibrah)*, dan *Sumber Rujukan*.
  - [x] Aktifkan menu **Quotes dan kisah Islam** di `_MoreScreen` dan perbarui `AboutScreen`.
- [x] **Pengujian**
  - [x] Tambah unit test, dataset validation test, widget test, dan navigation test (`test/quotes_stories_test.dart`).

---

## Fase L-3 — Halaman Lainnya: Tokoh Islam

Target: mengaktifkan menu **Tokoh Islam** di `_MoreScreen` (100% offline).

- [x] **Konten & Kurasi Biografi**
  - [x] Susun `assets/islamic/islamic_figures.json` mencakup kategori utama (*Nabi & Rasul*, *Sahabat*, *Ulama & Imam*, *Ilmuwan Muslim*, *Tokoh Nusantara*) lengkap dengan `id`, `name`, `arabic_name`, `epithet`, `category`, `era_label`, `summary`, `biography_sections`, `key_lessons`, `references` + blok `_meta`.
  - [x] Verifikasi akurasi sejarah dan cantumkan catatan bila terdapat perbedaan riwayat tahun.
  - [x] Daftarkan aset di `pubspec.yaml` dan buat tes validasi data.
- [x] **Domain & Data (`lib/features/islamic_figures/`)**
  - [x] Buat model `IslamicFigure`, `FigureCategory`, fungsi filter kategori/era, dan pencarian nama/julukan.
  - [x] Buat repository lokal dan integrasi bookmark/favorit.
  - [x] Buat controller layar daftar dan detail.
- [x] **Presentasi & Integrasi**
  - [x] Buat `IslamicFiguresScreen` (pencarian, `FilterChip` kategori/era, kartu profil bermonogram, filter favorit).
  - [x] Buat `IslamicFigureDetailScreen` (ringkasan, perjalanan hidup & kontribusi, keteladanan utama, daftar rujukan, aksi bookmark & salin).
  - [x] Aktifkan menu **Tokoh Islam** di `_MoreScreen` dan perbarui `AboutScreen`.
- [x] **Pengujian & Dokumentasi**
  - [x] Tambah unit test, widget test, dan navigation test (`test/islamic_figures_test.dart`).
  - [ ] Buat catatan implementasi `docs/prd-10-islamic-figures.md`.

---

## Fase L-4 — Halaman Lainnya: Kajian dan Ceramah

Target: mengaktifkan menu **Kajian dan ceramah** di `_MoreScreen` dengan sumber resmi berizin.

- [x] **Persiapan Sumber & Lisensi (Model RSS Terbuka Tanpa Scraping)**
  - [x] Gunakan standar feed RSS 2.0 / Podcast XML terbuka dari sumber resmi pilihan pengguna (tanpa scraping stream tidak resmi).
  - [x] Dokumentasikan syarat penggunaan, atribusi pemateri/penerbit, dan mekanisme nonaktifkan/hapus sumber kapan saja (`docs/prd-11-kajian.md`, `AboutScreen`).
- [x] **Domain & Data (`lib/features/kajian/`)**
  - [x] Buat model `KajianItem`, `KajianCategory`, `KajianSource` (metadata judul, pemateri, durasi, URL audio/tautan resmi, kategori, atribusi) dan parser RSS XML murni Dart (`kajian_rss_parser.dart`).
  - [x] Buat sumber katalog RSS (`DioKajianFeedClient`) + cache SQLite (`kajian_catalog_cache`, migrasi aditif v10 setara native & web).
  - [x] Buat repository dengan kebijakan cache/jaringan/offline yang jujur, serta simpan favorit & riwayat putar terakhir.
- [x] **Presentasi & Pemutar**
  - [x] Integrasikan pemutar audio kajian (`just_audio`, play/pause, seek ±15 detik, kecepatan putar 0.75x-2.0x) dengan jeda otomatis pemutar murottal agar tidak bentrok.
  - [x] Buat `KajianListScreen` (pencarian, filter kategori/pemateri, banner status cache/offline, tab Semua/Tersimpan/Riwayat, kelola sumber RSS) dan `KajianDetailScreen` (pemutar, deskripsi, blok sumber & lisensi).
  - [x] Aktifkan menu **Kajian dan ceramah** di `_MoreScreen` dan perbarui `AboutScreen`.
- [x] **Pengujian & Dokumentasi**
  - [x] Tambah unit test (parsing RSS, kebijakan cache/offline, skema v10), widget test (fake player/source), dan navigation test (`test/kajian_schema_test.dart`, `test/kajian_test.dart`).
  - [x] Buat catatan implementasi `docs/prd-11-kajian.md`.

---

## Backlog Terpisah — Halaman "Aktivitas"

*(Dikerjakan setelah atau paralel dengan fitur halaman Lainnya)*

- [x] **Statistik membaca:** agregasi lokal progres tilawah, bookmark, grafik hafalan 7 hari, hari aktif beruntun, ringkasan tajwid, dan tasbih (`lib/features/reading_stats/`, `test/reading_stats_test.dart`).
- [x] **Koreksi bacaan (offline on-device):** sorotan kata benar/salah/terlewat langsung pada teks Rasm Utsmani, manajer unduhan model resmi `Abdou/quran-asr-small` terverifikasi SHA-256, serta akses dari halaman Baca dan tab Aktivitas (`lib/features/assessment/`, `test/recitation_check_test.dart`).
- [x] **Tasbih digital:** penghitung dzikir (target 33/99/kustom), preset bacaan, umpan balik getar, reset aman (`lib/features/tasbih/`, `test/tasbih_test.dart`).
- [x] **Doa dan dzikir:** katalog doa harian & dzikir pagi/petang 100% offline lengkap dengan rujukan hadis/sumber (`assets/islamic/doa_dzikir.json`, `lib/features/doa_dzikir/`, `test/doa_dzikir_test.dart`).

---

## Verifikasi Perangkat, Kepatuhan, dan Rilis

- [ ] **Verifikasi Perangkat Android Fisik:**
  - [ ] Uji izin lokasi, alarm presisi (`SCHEDULE_EXACT_ALARM`), dan notifikasi Waktu Salat setelah reboot ([prd-06-prayer-times.md](prd-06-prayer-times.md#10-sisa-pekerjaan-yang-diketahui)).
  - [ ] Uji kompas live Arah Kiblat dan kalibrasi sensor di hardware ([prd-07-qibla.md](prd-07-qibla.md#9-sisa-pekerjaan-yang-diketahui)).
  - [ ] Uji perekaman mikrofon dan inference ASR lokal (`sherpa_onnx`) pada perangkat Android fisik.
- [ ] **Verifikasi Kepatuhan & Konten:**
  - [ ] Konfirmasi izin tertulis terjemahan Indonesia Kemenag dan izin distribusi audio qari (khususnya `ar.muhammadalluhaidan`) sebelum rilis publik.
  - [ ] Lakukan tashih konten teks Al-Qur'an dan peninjauan keabsahan rujukan pada fitur halaman Lainnya.
  - [ ] Siapkan mekanisme penonaktifan suara/kajian jarak jauh bila pemilik hak meminta penghapusan.
- [ ] **Rilis:**
  - [ ] Pastikan `flutter analyze` dan seluruh `flutter test` hijau pada Flutter versi `.fvmrc`.
  - [ ] Siapkan listing Google Play (deskripsi, tangkapan layar, kebijakan privasi) untuk rilis publik.
