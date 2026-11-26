# PRD — TILAWAHKU

*Aplikasi Al-Qur'an offline-first dengan Rasm Utsmani, terjemahan Indonesia, murottal, hafalan berbasis AI, serta fitur ibadah dan wawasan Islami.*  
Versi 2.0 · Diperbarui 24 November 2026

---

## 1. Ringkasan Produk

**TILAWAHKU** adalah aplikasi Flutter lintas platform (**Android** utama, preview **Web**, **iOS** menyusul) untuk membaca Al-Qur'an dalam **Rasm Utsmani**, transliterasi Latin, dan **terjemahan Indonesia**, mendengarkan murottal yang dapat diulang secara fleksibel, berlatih **hafalan** (termasuk penilaian setoran suara berbasis ASR lokal), mempelajari **Tajwid**, serta mengakses fitur pendukung ibadah dan wawasan Islami pada tab **Lainnya**.

| Item | Keputusan Aktual |
| --- | --- |
| Nama | TILAWAHKU |
| Identitas visual | Biru tua (`#132A4C`), biru sekunder (`#2C4870`), emas (`#E6B325`), krem kertas (`#EDEAE0`) |
| Teks Al-Qur'an | Rasm Utsmani (riwayat Hafs), transliterasi Latin, terjemahan Bahasa Indonesia (30 juz, 114 surah, 6.236 ayat) |
| Font Arab | Amiri Quran (SIL Open Font License 1.1) |
| Mode utama | Offline-first (teks & aset teks dibundel lokal; audio & layanan jadwal memakai cache lokal) |
| Lisensi source code | GNU General Public License v3.0 (GPL-3.0) |
| Model bisnis | Gratis, tanpa iklan, tanpa akun pengguna |

---

## 2. Latar Belakang dan Masalah

Pengguna Muslim di Indonesia — mulai dari orang tua, anak, pelajar, hingga penghafal Al-Qur'an — membutuhkan satu aplikasi Al-Qur'an yang tenang, bebas iklan, dapat diandalkan saat luring, dan terintegrasi dengan kebutuhan ibadah serta referensi keislaman harian:

- Banyak aplikasi Al-Qur'an terlalu bergantung pada internet dan penuh iklan yang mengganggu kekhusyukan.
- Fitur hafalan, latihan tajwid, jadwal salat, kiblat, dan kalender Hijriah sering tersebar di aplikasi terpisah.
- Pada halaman **Lainnya**, aplikasi sudah menyediakan slot untuk konten rujukan Islami (**Asmaul Husna**, **Kajian dan ceramah**, **Tokoh Islam**, serta **Quotes dan kisah Islam**) yang saat ini berstatus *"Belum tersedia"* dan membutuhkan spesifikasi produk, standar akurasi sumber, serta arsitektur data yang jelas sebelum diimplementasikan.
- Seluruh konten keagamaan harus memiliki atribusi sumber dan status lisensi yang jujur dan terdokumentasi.

---

## 3. Tujuan dan Metrik Keberhasilan

### Tujuan

- Mempertahankan pengalaman inti membaca, mendengar, menghafal, dan belajar tajwid yang cepat dan offline-first.
- Melengkapi seluruh fitur pada tab **Lainnya** (mengaktifkan 4 fitur yang masih berstatus *"Belum tersedia"*) dengan kualitas data terverifikasi dan pola UX konsisten.
- Menjaga kejelasan sumber, lisensi, dan perilaku jujur saat offline/tidak tersedia di tiap platform.

### Metrik Target

| Metrik | Target |
| --- | --- |
| Ayat dengan ketidakcocokan teks-audio saat QA | 0 dari 6.236 |
| Crash-free sessions | ≥ 99% |
| Waktu buka layar konten lokal (Baca, Asmaul Husna, Tokoh, Quotes/Kisah) | < 1 detik |
| Fitur teks pada tab Lainnya yang berjalan 100% offline | Asmaul Husna, Tokoh Islam, Quotes & Kisah Islam |
| Kepatuhan atribusi & lisensi konten | 100% konten memiliki sumber terdokumentasi |

---

## 4. Target Pengguna

| Persona | Kebutuhan Utama |
| --- | --- |
| **Orang tua** (30–45 tahun) | Membimbing anak membaca/menghafal Al-Qur'an, mengenal Asmaul Husna dan kisah teladan Islam |
| **Anak & pelajar** | Antarmuka jelas, tombol besar, latihan tajwid, hafalan, dan kisah tokoh Islam yang mudah dipahami |
| **Penghafal dewasa** | Pengulangan rentang ayat, program hafalan, setoran suara (AI), jadwal salat, dan kiblat |
| **Pengguna harian** | Membaca Al-Qur'an offline, jadwal salat & pengingat, kalender Hijriah, quotes hikmah, serta kajian |

---

## 5. Arsitektur Navigasi dan Peta Fitur

Aplikasi memakai 4 tab utama pada `NavigationBar` (`lib/features/navigation/presentation/main_navigation_screen.dart`):

| Tab | Fitur Sudah Tersedia | Fitur Direncanakan (*Belum tersedia*) |
| --- | --- | --- |
| **Beranda** | Sapaan waktu, kartu *Lanjutkan membaca*, ringkasan bacaan & hafalan, akses cepat (Waktu salat, Al-Qur'an, Program hafalan, Belajar Tajwid) | — |
| **Al-Qur’an** | Daftar 114 surah, 30 juz, halaman, bookmark, pencarian, halaman baca (Utsmani + Latin + terjemahan), pemutar audio (10 qari), mode ulang, unduhan per juz/surah | — |
| **Aktivitas** | Hafalan Al-Qur'an (program, latihan, setoran suara AI), Riwayat hafalan, Belajar Tajwid (materi & kuis) | Statistik membaca, Tasbih digital, Doa dan dzikir |
| **Lainnya** | Waktu salat, Arah kiblat, Kalender Hijriah, Pengaturan, Tentang aplikasi | **Asmaul Husna**, **Kajian dan ceramah**, **Tokoh Islam**, **Quotes dan kisah Islam** |

---

## 6. Alur Pengguna Halaman "Lainnya"

```text
Bottom Nav: Lainnya
  ├── Fitur Tambahan (Tersedia)
  │     ├── Waktu salat → Jadwal harian, hitung mundur, lokasi, pengingat
  │     ├── Arah kiblat → Kompas perangkat / dial manual (lokasi bersama)
  │     └── Kalender Hijriah → Tanggal Hijri, kalender bulanan, event penting
  ├── Fitur Tambahan (Target Pengembangan Berikutnya)
  │     ├── Asmaul Husna → Daftar 99 nama → Detail nama (Arab, latin, makna, dalil/catatan)
  │     ├── Kajian dan ceramah → Katalog kategori/pemateri → Detail & pemutar kajian
  │     ├── Tokoh Islam → Filter kategori/era & pencarian → Detail biografi + referensi
  │     └── Quotes dan kisah Islam → Tab Quotes / Tab Kisah → Detail & bagikan
  └── Aplikasi
        ├── Pengaturan → Tema, tampilan ayat, suara, unduhan
        └── Tentang aplikasi → Sumber konten, atribusi, lisensi
```

---

## 7. Kebutuhan Fungsional

Prioritas: **P0** wajib untuk rilis fitur terkait, **P1** penting, **P2** pengembangan lanjutan.

### 7.1–7.6 Fitur Inti dan Ibadah yang Sudah Tersedia (Baseline)

| Modul | Ringkasan Fitur Terimplementasi | Referensi Kode / Dokumen |
| --- | --- | --- |
| **Al-Qur'an & Baca** | 114 surah, 6.236 ayat `quran-uthmani`, `id.indonesian`, `en.transliteration`, navigasi surah/juz/halaman, bookmark, lanjutkan terakhir, ukuran huruf | `lib/features/reading/` |
| **Suara, Pemutar, Ulang, Unduh** | 10 qari di `assets/config/suara.json` (9 per-ayat + 1 per-surah streaming), background audio (`just_audio` + `audio_service`), repeat ayat/rentang/surah/juz, sleep timer, download manager per juz/surah | `lib/features/voices/`, `player/`, `repeat/`, `download/` |
| **Hafalan & AI Setoran Suara** | Program hafalan (surah/juz/rentang), target harian, mode belajar/hide-reveal/recall/audio/AI assessment (`sherpa_onnx` + `Abdou/quran-asr-small`), riwayat status | `lib/features/memorization/`, `assessment/` |
| **Belajar Tajwid** | Katalog materi hukum tajwid dan latihan kuis dengan penyimpanan riwayat percobaan | `lib/features/tajwid/` |
| **Waktu Salat (PRD 06)** | Jadwal 5 waktu dari AlAdhan API v1 + cache SQLite, hitung mundur, penyesuaian menit, pilihan metode & mazhab Asar, katalog 37 kota + GPS, pengingat lokal | [prd-06-prayer-times.md](prd-06-prayer-times.md) |
| **Arah Kiblat (PRD 07)** | Bearing lingkaran besar ke Ka'bah (offline), lokasi bersama dengan Waktu Salat, kompas perangkat (`flutter_device_compass`) + fallback dial manual | [prd-07-qibla.md](prd-07-qibla.md) |
| **Kalender Hijriah** | Tanggal Hijriah harian, kalender bulanan, daftar hari besar Islam, penyesuaian hari manual, cache SQLite bulanan | `lib/features/hijri/` |

---

### 7.7 Asmaul Husna *(Halaman Lainnya — Target Pengembangan)*

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| L1-01 | Menampilkan seluruh **99 Asmaul Husna** secara berurutan (nomor 1–99) dengan teks Arab berharakat, transliterasi Latin, dan arti Bahasa Indonesia | P0 |
| L1-02 | Pencarian cepat berdasarkan nomor, nama Latin, atau arti Bahasa Indonesia | P0 |
| L1-03 | Halaman/panel detail per nama berisi teks Arab besar (`AmiriQuran`), arti, uraian makna singkat, dan rujukan ayat Al-Qur'an terkait (bila ada) yang terverifikasi | P0 |
| L1-04 | Data dibundel lokal (JSON/SQLite) sehingga 100% tersedia offline tanpa internet | P0 |
| L1-05 | Bookmark / favorit nama dan tombol salin teks (Arab + Latin + arti) | P1 |
| L1-06 | Tautan langsung dari rujukan ayat pada detail nama ke layar baca Al-Qur'an (`ReadingScreen`) | P1 |
| L1-07 | Audio pelafalan per nama (hanya diaktifkan bila sumber rekaman berlisensi jelas tersedia) | P2 |

---

### 7.8 Kajian dan Ceramah *(Halaman Lainnya — Target Pengembangan)*

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| L2-01 | Menampilkan daftar kajian/ceramah terkurasi yang dilengkapi judul, nama pemateri/ustadz, kategori topik (Al-Qur'an, Akidah, Akhlak, Fiqih, Sirah, Keluarga), durasi, dan atribusi sumber resmi | P0 |
| L2-02 | Filter berdasarkan kategori/pemateri serta pencarian berdasarkan judul atau topik | P0 |
| L2-03 | Pemutar audio kajian terintegrasi (play, pause, seek, kecepatan putar, pemutaran latar belakang menggunakan `just_audio` + `audio_service`) atau pembukaan tautan resmi bila berupa video eksternal | P0 |
| L2-04 | Penanganan status jaringan yang jujur: katalog terakhir di-cache lokal; saat offline menampilkan keterangan bahwa pemutaran streaming membutuhkan internet (kecuali jika kajian sudah diunduh) | P0 |
| L2-05 | Penanda favorit / simpan kajian untuk diputar nanti dan catatan riwayat terakhir diputar | P1 |
| L2-06 | Unduhan audio kajian untuk pemutaran offline — **hanya** untuk sumber yang secara eksplisit mengizinkan redistribusi/unduhan lokal | P2 |

> **Prinsip kepatuhan:** Tidak melakukan scraping tidak resmi (misalnya ekstraksi stream YouTube tanpa izin). Sumber kajian harus berasal dari feed resmi berizin, podcast RSS terbuka, atau koleksi rekaman dengan persetujuan tertulis pemilik hak.

---

### 7.9 Tokoh Islam *(Halaman Lainnya — Target Pengembangan)*

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| L3-01 | Menampilkan katalog tokoh Islam terkurasi yang dikelompokkan per kategori/era (misalnya: Para Nabi & Rasul, Sahabat Nabi, Tabi'in & Imam Mazhab, Ulama & Ilmuwan Muslim, Tokoh Islam Nusantara) | P0 |
| L3-02 | Pencarian nama tokoh dan filter berdasarkan kategori/era | P0 |
| L3-03 | Layar detail biografi terstruktur: ringkasan singkat, masa hidup/periode (Hijriah & Masehi bila diketahui pasti), kontribusi utama, keteladanan/hikmah, serta daftar rujukan sejarah yang jelas | P0 |
| L3-04 | Konten teks dibundel lokal sehingga 100% tersedia offline | P0 |
| L3-05 | Fitur bookmark/favorit tokoh dan tombol salin ringkasan biografi | P1 |
| L3-06 | Indikator bila ada perbedaan riwayat tahun lahir/wafat secara jujur (tidak memaksakan angka tunggal yang tidak pasti) | P1 |

---

### 7.10 Quotes dan Kisah Islam *(Halaman Lainnya — Target Pengembangan)*

| ID | Kebutuhan | Prioritas |
| --- | --- | --- |
| L4-01 | Dua segmen/tab di dalam satu layar: **Quotes (Kutipan Hikmah)** dan **Kisah Islam** | P0 |
| L4-02 | Setiap **Quote** wajib mencantumkan teks kutipan (dan teks Arab bila ada), nama tokoh/sumber, serta rujukan kitab/ayat/hadis yang jelas (tanpa atribusi palsu) | P0 |
| L4-03 | Setiap **Kisah Islam** berisi judul, kategori (Kisah Qur'ani, Kisah Sahabat, Kisah Hikmah Ulama), estimasi waktu baca, isi cerita terstruktur, pelajaran (ibrah), dan sumber rujukan | P0 |
| L4-04 | Filter kategori dan pencarian untuk Quotes maupun Kisah | P0 |
| L4-05 | Seluruh konten teks dibundel lokal sehingga 100% dapat dibaca offline | P0 |
| L4-06 | Fitur simpan/favorit serta tombol **Salin** / **Bagikan** (teks dengan atribusi sumber) | P1 |
| L4-07 | Kartu kutipan harian (*Quote of the Day*) deterministik lokal tanpa membutuhkan server | P2 |

---

### 7.11 Backlog Halaman "Aktivitas" *(Tercatat untuk Konsistensi Roadmap)*

Tiga slot placeholder lain terdapat pada tab **Aktivitas** (`_ActivitiesScreen`), di luar fokus utama halaman **Lainnya**:

| Fitur | Ringkasan Rencana |
| --- | --- |
| **Statistik membaca** | Ringkasan jumlah ayat/halaman/durasi baca harian & mingguan berdasarkan data progres lokal |
| **Tasbih digital** | Penghitung dzikir dengan target (33/99/kustom), preset bacaan dzikir, umpan balik getar (haptic), dan reset aman |
| **Doa dan dzikir** | Kumpulan doa harian serta dzikir pagi & petang (Arab, Latin, arti, rujukan hadis/sumber) 100% offline |

---

## 8. Kebutuhan Non-Fungsional

| Aspek | Kebutuhan |
| --- | --- |
| **Offline-first** | Asmaul Husna, Tokoh Islam, dan Quotes & Kisah Islam harus berjalan 100% offline. Kajian memanfaatkan cache metadata dan status offline yang jujur. |
| **Kinerja** | Pembukaan daftar dan detail konten lokal < 1 detik; aset JSON dimemoisasi di memori setelah pemuatan pertama. |
| **Stabilitas & Pengujian** | Setiap fitur baru wajib memiliki unit test (domain/repository/controller), widget test (screen), dan navigation test dari `_MoreScreen`. |
| **Privasi** | Tidak ada akun, tidak ada pelacakan pengguna; seluruh favorit/riwayat disimpan lokal (SQLite / `SharedPreferences`). |
| **Aksesibilitas** | Target sentuh minimal 48 dp, kontras tinggi di mode terang dan gelap, dukungan skala ukuran teks untuk konten baca panjang (Kisah & Biografi). |
| **Integritas Konten Keagamaan** | Tidak mengarang dalil, ayat, atau hadis; setiap kutipan hadis/sejarah mencantumkan sumber rujukan; tidak mencampur teks Al-Qur'an dengan teks non-Qur'an. |

---

## 9. Arsitektur dan Data

### 9.1 Struktur Modul Fitur

Mengikuti pola arsitektur berlapis (`domain/`, `data/`, `presentation/`) seperti `lib/features/prayer/`, `qibla/`, dan `hijri/`:

- `lib/features/asmaul_husna/` — data lokal `assets/islamic/asmaul_husna.json`
- `lib/features/kajian/` — katalog JSON/RSS terverifikasi + cache SQLite + integrasi audio player
- `lib/features/islamic_figures/` — data lokal `assets/islamic/islamic_figures.json`
- `lib/features/quotes_stories/` — data lokal `assets/islamic/quotes.json` & `assets/islamic/stories.json`

Widget presentasi bersifat baca-saja terhadap state dari controller/repository; seluruh logika filter, pencarian, dan penyimpanan berada di lapisan domain/data.

### 9.2 Skema Database SQLite (Saat Ini: `DatabaseSchema.version = 9`)

Tabel yang sudah ada pada v9 (`lib/core/database/database_schema.dart`):
- Inti Qur'an & Audio: `surah`, `ayah`, `terjemah`, `transliterasi`, `suara`, `audio`, `bookmark`, `progres`, `audio_package`, `content_metadata`
- Hafalan: `memorization_program`, `memorization_ayah_progress`, `memorization_session`, `memorization_session_ayah`, `memorization_status_history`
- Tajwid: `tajwid_quiz_attempt`
- Ibadah: `prayer_schedule_cache`, `hijri_calendar_cache`

Rencana perluasan skema (murni aditif, setara di `app_database_native.dart` dan `app_database_web.dart`):
- **v10+ (bila diperlukan):** tabel generik `content_bookmark(content_type, content_id, created_at)` untuk favorit lintas fitur halaman **Lainnya** (Asmaul Husna, Tokoh Islam, Quotes/Kisah, Kajian), serta tabel `kajian_catalog_cache` untuk cache katalog kajian.

---

## 10. Lisensi dan Kepatuhan

- **Source code TILAWAHKU:** berlisensi **GNU General Public License v3.0 (GPL-3.0)** — lihat [LICENSE](../LICENSE).
- **Aset pihak ketiga yang sudah ada:**
  - Font **Amiri Quran**: SIL Open Font License 1.1 (`assets/fonts/OFL.txt`).
  - Model ASR **Abdou/quran-asr-small**: MIT License (`web/asr/LICENSE`).
  - Teks Qur'an, terjemahan Indonesia, transliterasi, dan manifest audio: AlQuran.cloud (ketentuan non-komersial, wajib atribusi, tidak mengubah teks).
  - Jadwal salat & data kota: AlAdhan API v1 & OpenStreetMap Nominatim (ODbL 1.0).
- **Ketentuan aset untuk 4 fitur baru halaman Lainnya:**
  - Seluruh teks uraian **Asmaul Husna**, **Tokoh Islam**, dan **Quotes & Kisah Islam** harus ditulis orisinal oleh tim dengan rujukan sumber primer/sekunder yang jelas atau diambil dari sumber berlisensi terbuka yang kompatibel (dicatat di halaman *Tentang aplikasi* dan metadata berkas `_meta`).
  - Sumber **Kajian dan ceramah** wajib diverifikasi hak distribusi/streaming-nya sebelum diaktifkan di katalog aplikasi.

---

## 11. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
| --- | --- | --- |
| Kesalahan atribusi hadis/quote atau fakta sejarah tokoh Islam | Menurunkan kepercayaan dan melanggar integritas konten keagamaan | Terapkan checklist verifikasi sumber di setiap entri JSON (`source_ref`), hindari kutipan tanpa rujukan jelas |
| Pelanggaran hak cipta audio/video pada fitur Kajian | Risiko penghapusan aplikasi dari toko aplikasi | Hanya gunakan sumber resmi berizin/RSS terbuka, sediakan mekanisme nonaktifkan/hapus item dari katalog |
| Pembengkakan ukuran APK akibat aset baru | Aplikasi berat di perangkat spesifikasi rendah | Konten teks disimpan sebagai JSON terstruktur ringkas (ukuran puluhan KB); audio/media kajian tidak dibundel ke dalam APK |
| Perbedaan dukungan platform (Android vs Web) | Fitur rusak di salah satu platform | Pisahkan binding platform secara bersyarat dan tampilkan pesan keterbatasan secara jujur seperti pada PRD 06 dan PRD 07 |

---

## 12. Kriteria Penerimaan per Fitur Halaman "Lainnya"

Sebuah fitur pada `_MoreScreen` baru boleh diubah dari `_UnavailableAction` ("Belum tersedia") menjadi `_DashboardAction` aktif apabila:

1. Seluruh kebutuhan **P0** fitur tersebut selesai diimplementasikan.
2. Konten telah melewati pemeriksaan akurasi sumber & lisensi (terdokumentasi di `_meta` dan halaman *Tentang aplikasi*).
3. `dart analyze` bersih dan seluruh tes (unit, widget, serta tes navigasi dari tab **Lainnya**) lolos.
4. Perilaku mode offline, mode gelap, ukuran teks, dan tampilan kosong/error telah diuji.
