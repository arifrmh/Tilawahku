# Design — TILAWAHKU

Spesifikasi desain visual, arsitektur informasi, dan UX aplikasi TILAWAHKU (v2.0 · 24 November 2026), diselaraskan dengan `lib/app/app_theme.dart`, `main_navigation_screen.dart`, serta rancangan 4 fitur baru pada halaman **Lainnya**.

---

## 1. Prinsip Desain

- **Khidmat dan tenang:** identitas warna biru tua (`navy`) dan emas (`gold`) di atas permukaan krem lembut (`parchment`) pada mode terang atau biru tua pada mode gelap.
- **Konsisten lintas fitur:** seluruh fitur baru di halaman **Lainnya** menggunakan komponen `Card` (`BorderRadius(20)`), `ListTile`, `FilledButton`, dan `OutlinedButton` dari `AppTheme` tanpa gaya terpisah.
- **Keterbacaan tinggi:** teks Arab menggunakan font `AmiriQuran` berukuran lega; konten baca panjang (biografi tokoh & kisah Islam) memakai spasi baris nyaman (`height: 1.6`) dan mendukung skala ukuran teks.
- **Aksesibilitas:** target sentuh minimal **48 × 48 dp**, kontras tinggi di mode terang & gelap, label semantik jelas.
- **Status jujur:** saat perangkat offline atau fitur belum aktif, UI menyatakan kondisi sebenarnya beserta aksi alternatif (coba lagi / filter lokal), bukan layar kosong.

---

## 2. Palet Warna Aktual (`lib/app/app_theme.dart`)

| Token (`AppColors`) | Hex | Peran (Mode Terang) | Peran (Mode Gelap) |
| --- | --- | --- | --- |
| `navy` / `darkNavy` | `#132A4C` | Teks utama, tombol primer, kartu sorotan | Latar utama (`scaffoldBackgroundColor`) |
| `gold` | `#E6B325` | Aksen, ikon `ListTile`, tombol `FilledButton`, indikator tab | Warna primer, aksen, tombol, ikon aktif |
| `parchment` / `lightSurface` | `#EDEAE0` | Latar utama & permukaan kartu | Teks utama (`foreground`) |
| `blue` / `translation` | `#2C4870` | Teks terjemahan, border sekunder, tab tidak aktif | Permukaan kartu (`Card`), dialog, menu |

---

## 3. Tipografi

| Elemen | Font | Catatan |
| --- | --- | --- |
| Teks Arab (Al-Qur'an, Asmaul Husna, kutipan Arab) | **AmiriQuran** (`assets/fonts/AmiriQuran-Regular.ttf`, SIL OFL 1.1) | Arah teks `TextDirection.rtl`, ukuran besar dan lega |
| UI, Terjemahan, Biografi, Kisah | Material 3 sans-serif default | Mendukung penyesuaian ukuran teks dari Pengaturan untuk keterbacaan |

---

## 4. Peta Layar (*Information Architecture*)

```text
Splash / Onboarding (pertama kali) → Pilih Suara
  └── MainNavigationScreen (4 tab NavigationBar)
        ├── [0] Beranda (_HomeDashboard)
        │     ├── Lanjutkan membaca → ReadingScreen
        │     └── Akses cepat: Waktu salat, Al-Qur'an, Program hafalan, Belajar Tajwid
        ├── [1] Al-Qur'an (HomeScreen)
        │     └── Surah / Juz / Halaman / Bookmark → ReadingScreen + Player + Repeat + Unduhan
        ├── [2] Aktivitas (_ActivitiesScreen)
        │     ├── Tersedia: Hafalan Al-Qur'an (+ AI Setoran Suara), Riwayat hafalan, Belajar Tajwid
        │     └── Backlog: Statistik membaca, Tasbih digital, Doa dan dzikir
        └── [3] Lainnya (_MoreScreen)
              ├── Tersedia:
              │     ├── Waktu salat (PrayerTimesScreen)
              │     ├── Arah kiblat (QiblaScreen)
              │     └── Kalender Hijriah (HijriCalendarScreen)
              ├── Target Pengembangan (Halaman Lainnya):
              │     ├── Asmaul Husna (AsmaulHusnaScreen → Detail Sheet/Screen)
              │     ├── Kajian dan ceramah (KajianListScreen → KajianDetailScreen)
              │     ├── Tokoh Islam (IslamicFiguresScreen → IslamicFigureDetailScreen)
              │     └── Quotes dan kisah Islam (QuotesStoriesScreen → StoryDetailScreen)
              └── Aplikasi:
                    ├── Pengaturan (SettingsScreen)
                    └── Tentang aplikasi (AboutScreen)
```

---

## 5. Rincian Desain Halaman "Lainnya"

### 5.1 Daftar Menu Tab "Lainnya" (`_MoreScreen`)

- **Header bagian 1:** `Fitur tambahan`
  - Item aktif memakai `_DashboardAction` (`Card` + `ListTile` dengan ikon warna `gold`, judul, subjudul ringkas 1 baris, chevron kanan).
  - Item yang belum dirilis memakai `_UnavailableAction` (`subtitle: "Belum tersedia"`, ikon gembok, `enabled: false`).
  - Saat salah satu dari 4 fitur baru lulus kriteria penerimaan, itemnya langsung dipindahkan/diaktifkan menjadi `_DashboardAction` dengan subjudul deskriptif.
- **Header bagian 2:** `Pengaturan` dan `Tentang aplikasi` dipisahkan jarak `SizedBox(height: 12)`.

---

### 5.2 Desain Fitur 1: Asmaul Husna

- **Layar Utama (`AsmaulHusnaScreen`):**
  - `AppBar`: judul `"Asmaul Husna"`, aksi filter *Semua / Favorit*.
  - Kolom pencarian (`SearchBar` / `TextField` terpadu) untuk mencari berdasarkan nomor (`1–99`), nama Latin (mis. `Ar-Rahman`), atau arti (mis. `Pengasih`).
  - Daftar atau grid adaptif 99 kartu (`ListView` / `GridView` responsif):
    - Badge nomor emas (`1`–`99`),
    - Teks Arab `AmiriQuran` berukuran jelas (kanan/atas),
    - Transliterasi Latin tebal + arti singkat Bahasa Indonesia,
    - Ikon favorit (bintang/hati) dengan target sentuh ≥ 48 dp.
- **Layar / Lembar Detail (`AsmaulHusnaDetailSheet` atau Screen):**
  - Header kartu bernuansa `navy` dengan teks Arab besar (`parchment`/`gold`), transliterasi, dan arti utama.
  - Bagian **Makna & Penghayatan** (1–2 paragraf singkat).
  - Bagian **Rujukan Al-Qur'an** (chip/kartu ayat terkait yang dapat diketuk untuk membuka `ReadingScreen` pada ayat tersebut).
  - Baris aksi bawah: tombol **Salin**, **Favorit**, dan navigasi **Sebelumnya / Berikutnya** agar pengguna mudah menelusuri berurutan.

---

### 5.3 Desain Fitur 2: Kajian dan Ceramah

- **Layar Utama (`KajianListScreen`):**
  - `AppBar`: judul `"Kajian dan ceramah"`, tombol muat ulang katalog, filter *Tersimpan*.
  - Kolom pencarian (judul / pemateri) + baris `FilterChip` horizontal untuk kategori (Semua, Al-Qur'an, Akidah, Akhlak, Fiqih, Sirah, Keluarga).
  - Banner info ringkas bila luring: menjelaskan bahwa daftar berasal dari cache terakhir dan streaming membutuhkan koneksi internet.
  - Kartu kajian:
    - Tag kategori & durasi (mis. `Akhlak · 32 mnt`),
    - Judul kajian (maks. 2 baris),
    - Nama pemateri & label sumber resmi,
    - Ikon status jenis media (audio dalam aplikasi vs tautan eksternal) dan tombol simpan/favorit.
- **Layar Detail & Pemutar (`KajianDetailScreen`):**
  - Info pemateri, kategori, ringkasan materi, dan blok **Sumber & Lisensi** yang terlihat jelas.
  - Kontrol pemutar konsisten dengan pemutar murottal: Play/Pause, mundur/maju 15 detik, slider durasi, kecepatan putar (`0,75x–1,5x`), serta kontrol notifikasi latar belakang.
  - Bila perangkat offline dan audio tidak tersedia lokal, tombol putar menampilkan pesan gagal/arahan yang jelas, bukan loading tanpa akhir.

---

### 5.4 Desain Fitur 3: Tokoh Islam

- **Layar Utama (`IslamicFiguresScreen`):**
  - `AppBar`: judul `"Tokoh Islam"`, tombol toggle *Favorit*.
  - Kolom pencarian nama/julukan + `FilterChip` kategori/era (*Semua*, *Nabi & Rasul*, *Sahabat*, *Ulama & Imam*, *Ilmuwan Muslim*, *Tokoh Nusantara*).
  - Kartu tokoh:
    - Monogram/ikon kategori dalam `CircleAvatar` (warna `navy`/`gold`, tidak bergantung pada gambar wajah tokoh),
    - Nama tokoh + gelar/julukan,
    - Periode hidup (Hijriah/Masehi) & bidang kontribusi singkat,
    - Ikon bookmark.
- **Layar Detail Biografi (`IslamicFigureDetailScreen`):**
  - Header ringkas: nama lengkap, nama Arab (opsional), julukan, periode, dan kategori.
  - Seksi terstruktur dalam kartu terpisah:
    1. **Ringkasan Profil**
    2. **Perjalanan Hidup & Kontribusi**
    3. **Keteladanan Utama** (poin-poin singkat)
    4. **Rujukan Sumber** (daftar kitab/referensi sejarah).
  - Aksi di `AppBar`: **Bookmark** dan **Salin ringkasan**.

---

### 5.5 Desain Fitur 4: Quotes dan Kisah Islam

- **Layar Utama (`QuotesStoriesScreen`):**
  - `AppBar`: judul `"Quotes dan kisah Islam"`, tombol filter *Favorit*, serta `TabBar` di bawahnya dengan 2 tab: **Quotes** dan **Kisah**.
- **Tab 1 — Quotes:**
  - `FilterChip` tema (Semua, Al-Qur'an, Sabar, Syukur, Ilmu, Akhlak).
  - Kartu kutipan sorotan bergaya `navy` + garis aksen `gold` (seperti `_ContinueReadingCard` pada Beranda):
    - Teks kutipan jelas (dan teks Arab `AmiriQuran` opsional di atasnya),
    - Nama sumber/tokoh & rujukan kitab/ayat di bagian bawah,
    - Baris aksi: **Favorit**, **Salin**, **Bagikan**.
- **Tab 2 — Kisah Islam:**
  - Kolom pencarian + `FilterChip` kategori (*Kisah Qur'ani*, *Kisah Sahabat*, *Kisah Hikmah*).
  - Kartu daftar kisah: judul, kategori, estimasi waktu baca (mis. `3 mnt baca`), cuplikan 2 baris, dan ikon bookmark.
- **Layar Baca Kisah (`StoryDetailScreen`):**
  - Tata letak fokus membaca (margin lega, line-height `1.6`, kontrol ukuran huruf cepat `A- / A+`).
  - Bagian akhir khusus berbentuk kartu beraksen `gold`: **Pelajaran (Ibrah)** dan **Sumber Rujukan**.
  - Aksi: **Favorit** dan **Bagikan ringkasan**.

---

## 6. Komponen Bersama yang Digunakan Ulang

Untuk menjaga konsistensi kode dan tampilan, keempat fitur di halaman **Lainnya** menggunakan komponen bersama:

- **Search & Filter Bar:** kolom pencarian + `FilterChip` horizontal yang konsisten di mode terang & gelap.
- **State View (Empty / Offline / Error):** memakai pola `_DashboardMessage` (ikon 48 px, judul, detail singkat, tombol aksi).
- **Source Attribution Footer:** blok catatan sumber & lisensi kecil di bagian bawah layar detail agar transparan kepada pengguna.
- **Bookmark Toggle Button:** tombol ikon minimal 48 × 48 dp dengan umpan balik `SnackBar` ringkas saat disimpan/dihapus.
