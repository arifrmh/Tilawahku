# PRD 11: Kajian dan Ceramah (RSS Podcast Terbuka)

Dokumen catatan implementasi fitur **Kajian dan ceramah** pada tab **Lainnya** (`lib/features/kajian/`).

## 1. Kebijakan Sumber dan Kepatuhan Lisensi

- Tilawahku **tidak** membundel audio pihak ketiga di dalam APK dan **tidak** melakukan scraping tidak resmi (seperti ekstraksi stream YouTube tanpa izin).
- Fitur ini menggunakan standar terbuka **RSS 2.0 / Podcast XML** (`<channel>`, `<item>`, `<enclosure type="audio/...">`, `<itunes:author>`, `<itunes:duration>`, `<copyright>`).
- Pengguna menambahkan dan mengelola sendiri URL feed RSS kajian resmi dari lembaga atau pemateri.
- Setiap item menampilkan blok **Sumber dan lisensi** yang transparan (penerbit, pemateri, catatan lisensi/copyright, URL feed, dan tautan resmi).
- Mekanisme penonaktifan dan penghapusan sumber tersedia langsung melalui menu **Kelola sumber RSS** (`setSourceEnabled` dan `removeSource`), sehingga feed dapat segera dihentikan bila diminta pemilik hak.

## 2. Arsitektur dan Penyimpanan

- **Domain (`lib/features/kajian/domain/`):**
  - `kajian_models.dart`: model `KajianSource`, `KajianItem`, `KajianCategory`, `KajianPlaybackRecord`, `KajianCatalogSnapshot`, `KajianPlaybackState`, validasi URL (`http`/`https`), dan fungsi filter/ekstraksi pemateri.
  - `kajian_rss_parser.dart`: parser RSS 2.0 / Podcast XML murni Dart tanpa tambahan dependensi eksternal. Hanya menerima episode dengan `<enclosure>` audio valid, membersihkan CDATA/HTML, dan mengurai durasi (`HH:MM:SS`, `MM:SS`, atau detik).
- **Data (`lib/features/kajian/data/`):**
  - **Migrasi SQLite v10 (aditif, setara native dan web):** tabel `kajian_catalog_cache(feed_url, source_json, items_json, fetched_at)` di `DatabaseSchema`, `app_database_native.dart`, dan `app_database_web.dart`.
  - `KajianFeedClient` (`DioKajianFeedClient`): mengambil XML RSS dengan batas waktu 15 detik dan pesan jaringan yang jelas.
  - `KajianRepository`: menyimpan daftar sumber, favorit, dan riwayat putar (maksimal 50 entri terakhir) di `AppPreferences`, dengan TTL cache 6 jam dan fallback jujur ke cache lokal saat jaringan gagal.
  - `KajianAudioPlayback` (`JustAudioKajianPlayback`): pemutar streaming berbasis `just_audio` dengan kontrol play/pause, seek bar, mundur/maju 15 detik, dan kecepatan putar `0.75x` sampai `2.0x`. Sebelum memutar kajian, pemutar otomatis menjeda `QuranAudioHandler` bila murottal sedang aktif agar dua audio tidak bertabrakan.
- **Presentasi (`lib/features/kajian/presentation/`):**
  - `KajianListScreen`: tab **Semua**, **Tersimpan**, dan **Riwayat**, pencarian, filter kategori dan pemateri, banner status cache/offline jujur, dialog tambah sumber RSS, sheet kelola sumber, serta mini-player di bagian bawah.
  - `KajianDetailScreen`: kartu header navy-emas, pemutar audio lengkap, ringkasan kajian, dan kartu **Sumber dan lisensi**.

## 3. Cakupan Pengujian

- `test/kajian_schema_test.dart`: memverifikasi migrasi aditif v10 dan kesetaraan `app_database_native.dart` serta `app_database_web.dart`.
- `test/kajian_test.dart`: memverifikasi parser RSS, kebijakan cache/offline repository, koordinasi jeda murottal, alur UI (onboarding kosong, tambah RSS, filter, pemutar detail, sumber & lisensi), serta navigasi dari tab **Lainnya**.

## 4. Batasan yang Diketahui

- Pemutaran audio kajian saat ini bersifat streaming langsung dari URL enclosure penerbit (memerlukan internet); unduhan offline kajian sengaja belum diaktifkan hingga ada sumber dengan izin redistribusi unduhan tertulis.
- Pemutaran latar belakang penuh dengan kontrol notifikasi media terpisah untuk kajian belum digabung ke `QuranAudioHandler` agar manajemen antrean dan mode ulang murottal tetap terisolasi.
