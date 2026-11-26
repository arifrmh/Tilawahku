# Dokumentasi Proyek — TILAWAHKU

Direktori ini menyimpan seluruh dokumen perencanaan, ruang lingkup, desain, roadmap tugas, serta catatan implementasi fitur untuk aplikasi **TILAWAHKU**.

## Daftar Dokumen

| Dokumen | Isi |
| --- | --- |
| [PRD.md](PRD.md) | Product Requirements Document (v2.0): kondisi fitur aktual aplikasi serta spesifikasi fungsional untuk pengembangan fitur di halaman **Lainnya** (dan backlog halaman **Aktivitas**). |
| [Scope.md](Scope.md) | Batasan ruang lingkup: fitur yang sudah tersedia, ruang lingkup 4 fitur baru di halaman **Lainnya**, backlog **Aktivitas**, hal-hal di luar scope, dan standar konten/lisensi. |
| [Design.md](Design.md) | Spesifikasi visual dan UX: palet warna & tipografi aktual (`AppTheme`), arsitektur navigasi 4 tab, serta rancangan layar & komponen untuk fitur di halaman **Lainnya**. |
| [Task.md](Task.md) | Daftar tugas dan progres pengembangan: status fitur yang sudah selesai, rincian checklist 4 fitur halaman **Lainnya**, backlog **Aktivitas**, dan tugas verifikasi rilis. |
| [prd-06-prayer-times.md](prd-06-prayer-times.md) | Catatan implementasi & verifikasi fitur **Waktu Salat** (PRD 06). |
| [prd-07-qibla.md](prd-07-qibla.md) | Catatan implementasi & verifikasi fitur **Arah Kiblat** (PRD 07). |

## Ringkasan Status Fitur Halaman "Lainnya"

Merujuk pada `_MoreScreen` di `lib/features/navigation/presentation/main_navigation_screen.dart`:

| Fitur di Halaman Lainnya | Status | Referensi |
| --- | --- | --- |
| Waktu salat | Tersedia | [prd-06-prayer-times.md](prd-06-prayer-times.md) |
| Arah kiblat | Tersedia | [prd-07-qibla.md](prd-07-qibla.md) |
| Kalender Hijriah | Tersedia | `lib/features/hijri/` |
| **Asmaul Husna** | Tersedia | `lib/features/asmaul_husna/` |
| **Kajian dan ceramah** | **Direncanakan (Belum tersedia)** | [PRD.md](PRD.md#78-kajian-dan-ceramah-halaman-lainnya) |
| **Tokoh Islam** | Tersedia | `lib/features/islamic_figures/` |
| **Quotes dan kisah Islam** | Tersedia | `lib/features/quotes_stories/` |
| Pengaturan | Tersedia | `lib/features/settings/` |
| Tentang aplikasi | Tersedia | `lib/features/about/` |
