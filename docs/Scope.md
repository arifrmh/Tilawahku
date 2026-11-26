# Scope — TILAWAHKU

Batasan ruang lingkup proyek TILAWAHKU (v2.0 · 24 November 2026), diturunkan dari [PRD.md](PRD.md) dan diselaraskan dengan implementasi aktual pada `lib/features/navigation/presentation/main_navigation_screen.dart`.

---

## 1. Baseline: Fitur yang Sudah Tersedia

Fitur-fitur berikut sudah terimplementasi di repositori dan dijaga agar tidak mengalami regresi:

- **Al-Qur'an Offline:** 30 juz, 114 surah, 6.236 ayat (Rasm Utsmani, transliterasi Latin, terjemahan Indonesia), navigasi surah/juz/halaman, pencarian surah, bookmark, lanjutkan terakhir, pengaturan ukuran huruf.
- **Audio & Mode Ulang:** 10 qari di `assets/config/suara.json`, pemutar latar belakang (`just_audio` + `audio_service`), repeat ayat/rentang/surah/juz, kecepatan putar, timer tidur, unduhan audio per juz/surah.
- **Hafalan & AI Setoran Suara:** program hafalan (surah/juz/rentang), target harian, mode latihan (`learn`, `hide_reveal`, `recall`, `audio_repetition`, `ai_assessment` via `sherpa_onnx`), riwayat hafalan.
- **Belajar Tajwid:** materi hukum bacaan tajwid dan latihan kuis dengan penyimpanan skor lokal.
- **Ibadah di Halaman "Lainnya":**
  - **Waktu Salat** ([prd-06-prayer-times.md](prd-06-prayer-times.md))
  - **Arah Kiblat** ([prd-07-qibla.md](prd-07-qibla.md))
  - **Kalender Hijriah** (`lib/features/hijri/`)
- **Aplikasi:** tema biru-emas (terang & gelap), Pengaturan, Tentang aplikasi, serta lisensi source code **GNU GPLv3**.

---

## 2. Ruang Lingkup Pengembangan Utama: Halaman "Lainnya"

Fokus pengembangan fase berikutnya adalah mengaktifkan **4 fitur** yang saat ini tampil sebagai *"Belum tersedia"* pada tab **Lainnya** (`_MoreScreen`):

| Urutan | Fitur | Termasuk dalam Scope | Tidak Termasuk pada Tahap Awal |
| --- | --- | --- | --- |
| 1 | **Asmaul Husna** | 99 nama lengkap (Arab, Latin, arti, penjelasan ringkas, rujukan ayat), pencarian, favorit, salin teks, 100% offline, tautan ke ayat terkait | Rekaman audio kustom (menunggu sumber berlisensi jelas), kuis/gamifikasi Asmaul Husna |
| 2 | **Quotes dan Kisah Islam** | 2 segmen (*Quotes* & *Kisah*), konten terkurasi berujukan sumber, filter kategori, pencarian, favorit, salin/bagikan teks, 100% offline | Kirim/unggah kutipan oleh pengguna, fitur komentar/like sosial, generator gambar beresolusi tinggi server-side |
| 3 | **Tokoh Islam** | Katalog biografi terkurasi per kategori/era, pencarian, halaman detail terstruktur + rujukan sejarah, favorit, 100% offline | Peta interaktif lokasi sejarah, ensiklopedia ratusan tokoh tanpa kurasi rujukan |
| 4 | **Kajian dan Ceramah** | Katalog kajian berizin/resmi per kategori & pemateri, pencarian, pemutar audio terintegrasi (`just_audio`/`audio_service`) atau tautan resmi, cache katalog, favorit, status offline jujur | Scraping video/stream tanpa izin, unggah kajian oleh pengguna, live streaming acara, unduhan massal tanpa izin pemilik hak |

---

## 3. Backlog Terpisah: Halaman "Aktivitas"

Tiga slot placeholder pada tab **Aktivitas** (`_ActivitiesScreen`) berada pada backlog terpisah setelah atau paralel dengan fitur halaman **Lainnya**:

- **Statistik membaca**
- **Tasbih digital**
- **Doa dan dzikir**

---

## 4. Eksplisit di Luar Scope

Item berikut **tidak dikerjakan** kecuali disetujui sebagai perubahan PRD terpisah:

| Item | Alasan |
| --- | --- |
| Akun pengguna, login, dan sinkronisasi cloud | Bertentangan dengan prinsip offline-first dan privasi tanpa pelacakan |
| Fitur sosial (komentar, profil publik, papan peringkat, berbagi ke feed internal) | Menambah beban moderasi dan kebutuhan backend |
| Iklan dan pembelian dalam aplikasi (IAP) | Model distribusi gratis tanpa iklan; konten AlQuran.cloud bersifat non-komersial |
| Qiraat selain Hafs 'an 'Asim | Fokus menjaga akurasi satu riwayat penuh terlebih dahulu |
| Scraping konten kajian/artikel pihak ketiga tanpa izin | Risiko pelanggaran hak cipta dan penghapusan dari toko aplikasi |
| Penetapan resmi awal bulan Hijriah / fatwa | Aplikasi hanya menyajikan hasil perhitungan dan rujukan edukatif |

---

## 5. Batasan Teknis dan Konten

| Aspek | Batasan |
| --- | --- |
| **Platform** | Android (utama), Web (preview dengan perilaku jujur bila sensor/notifikasi/audio tidak didukung), iOS (menyiapkan kompatibilitas, verifikasi hardware menyusul) |
| **Penyimpanan lokal** | Aset teks dibundel sebagai JSON di `assets/islamic/`; state favorit & cache memakai SQLite (`DatabaseSchema` aditif, setara native & web) atau `SharedPreferences` |
| **Navigasi** | Tidak menambah tab baru pada `NavigationBar`; seluruh 4 fitur baru diakses dari tab **Lainnya** |
| **Verifikasi konten** | Setiap berkas data JSON wajib memiliki blok `_meta` (sumber, lisensi, tanggal kurasi) dan tiap entri kutipan/kisah/biografi wajib memiliki referensi sumber |
| **Verifikasi perangkat** | Fitur yang bergantung pada hardware/OS Android (notifikasi salat, kompas kiblat, mikrofon ASR, background audio kajian) tidak diklaim terverifikasi sebelum diuji pada perangkat/emulator Android |

---

## 6. Kriteria Keluar dari Scope (*Out-of-Scope Triggers*)

Perubahan berikut memerlukan peninjauan ulang PRD sebelum dikerjakan:
- Membutuhkan backend server kustom, autentikasi pengguna, atau database cloud.
- Membutuhkan biaya langganan API berbayar atau kunci rahasia yang ditanam di aplikasi.
- Membundel berkas audio/video besar (> 5 MB) ke dalam APK.
- Memasukkan konten keagamaan tanpa sumber rujukan atau izin lisensi yang jelas.
