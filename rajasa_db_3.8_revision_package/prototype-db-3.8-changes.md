# DB 3.8 Changes - Kontrak Data Minimal, Rombel Tanpa Inkremen, dan Lokasi Presensi Fleksibel

Tanggal revisi: 2026-05-11  
Basis: `prototype-db-3.7.sql`  
Output: `prototype-db-3.8.sql`

## 1. Tujuan revisi

DB 3.8 dibuat untuk mengunci keputusan desain setelah revisi batasan data mitra. Fokus utamanya adalah menyesuaikan DB 3.7 agar MVP tidak bergantung pada data yang tidak disediakan mitra.

Data yang dipastikan tersedia dari mitra hanya:

| Kolom | Makna sistem |
|---|---|
| `NO` | Nomor urut sumber import. Default bukan nomor absen. |
| `NISN` | Identitas nasional siswa. Disimpan sebagai teks. |
| `NAMA` | Nama lengkap siswa. |
| `KELAS` | Label kelas akademik/rombel sederhana. Contoh: `10 AKL`. |

DB 3.8 juga mengunci keputusan bahwa `10 AKL` tidak boleh ditampilkan sebagai `10 AKL 1` ketika hanya ada satu rombel.

```text
Input mitra  : 10 AKL
Internal DB  : tingkatan = X, tingkat_angka = 10, jurusan = AKL, nomor_rombel = 1
Tampilan UI  : 10 AKL
Bukan        : 10 AKL 1
```

## 2. Keputusan desain utama

### 2.1 Tidak melakukan hard pruning

DB 3.8 tetap mempertahankan kompleksitas DB 3.7 sebagai roadmap. Revisi dilakukan melalui `scope pruning`, yaitu menyesuaikan tabel yang terdampak langsung oleh data mitra dan alur MVP.

### 2.2 Rombel internal dan tampilan dibedakan

`nomor_rombel = 1` tetap boleh dipakai secara internal. Namun, angka tersebut tidak otomatis menjadi bagian dari tampilan guru/admin apabila sumber data hanya menulis `10 AKL`.

### 2.3 Kelas akademik bukan ruangan fisik

Kolom `KELAS` dari mitra tidak boleh dianggap sebagai ruangan. Ruangan/lokasi presensi ditangani sebagai konteks sesi, bukan mapping permanen yang wajib diperbarui setiap hari.

### 2.4 Presensi berbasis sesi rombel

Presensi QR web diarahkan menggunakan `scanner_session_id + siswa_id` sebagai kunci anti duplikasi utama untuk satu sesi.

## 3. Perubahan tabel

### 3.1 Tabel `siswa`

Perubahan:

| Kolom | DB 3.7 | DB 3.8 |
|---|---|---|
| `jenis_kelamin` | NOT NULL | NULL |
| `angkatan` | NOT NULL | NULL |
| `kelas_aktif` | cache umum | cache label familiar, contoh `10 AKL` |

Alasan: data mitra tidak menyediakan gender dan angkatan. Sistem tidak boleh membuat data palsu.

### 3.2 Tabel `rombel`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `tingkat_angka` | Menyimpan angka 10/11/12/13 untuk tampilan UI. |
| `is_nomor_rombel_inferred` | Menandai nomor rombel dibuat otomatis dari kondisi satu rombel. |
| `label_rombel_raw` | Menyimpan label mentah dari import, misalnya `10 AKL`. |
| `display_mode` | Mengatur tampilan: `tanpa_nomor`, `dengan_nomor`, atau `custom`. |
| `is_inferred_from_import` | Menandai rombel yang dibuat otomatis dari file import. |

Aturan tampilan:

| Kondisi | Display |
|---|---|
| Data sumber `10 AKL`, tidak ada nomor rombel eksplisit | `10 AKL` |
| Data sumber `10 AKL 2` atau admin memilih nomor eksplisit | `10 AKL 2` |
| Admin mengatur custom label | mengikuti `label_rombel` |

### 3.3 Tabel `import_jobs`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `source_contract_version` | Menandai kontrak data sumber, default `mitra-minimal-v1`. |
| `use_no_as_absen` | Opsi sadar untuk memakai `NO` sebagai nomor absen. Default `0`. |
| `kelas_display_mode` | Aturan tampilan hasil parser kelas. Default `tanpa_nomor`. |

### 3.4 Tabel `import_row_logs`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `source_no` | Nilai `NO` mentah dari file. |
| `source_nisn` | Nilai `NISN` mentah dari file. |
| `source_nama` | Nilai `NAMA` mentah dari file. |
| `source_kelas` | Nilai `KELAS` mentah dari file. |
| `normalized_rombel_label` | Hasil normalisasi untuk UI, contoh `10 AKL`. |
| `use_no_as_absen` | Snapshot opsi import. |

Kolom ini membantu audit import dan mencegah kesalahan tafsir bahwa `NO` otomatis nomor absen.

### 3.5 Tabel `scanner_sessions`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `selected_rombel_label_snapshot` | Snapshot label rombel saat sesi dibuka. |
| `lokasi_mode` | Mode lokasi: `master_ruangan`, `input_manual`, `tidak_dicatat`, `fleksibel`. |
| `ruangan_label_manual` | Nama lokasi manual dari guru/operator. |
| `ruangan_label_snapshot` | Snapshot lokasi saat sesi dibuka. |

Perubahan: `ruangan_id` tetap ada, tetapi menjadi konteks opsional. Sesi scan dapat berjalan tanpa mapping permanen `rombel -> ruangan`.

### 3.6 Tabel `presensi`

Perubahan:

| Area | Perubahan |
|---|---|
| `ruangan_id` | Menjadi nullable. |
| `lokasi_mode` | Snapshot mode lokasi dari sesi presensi. |
| `ruangan_label_snapshot` | Snapshot lokasi saat presensi dibuat. |
| `rombel_display_snapshot` | Snapshot label rombel tampilan, contoh `10 AKL`. |
| Unique session | Tambah `uk_presensi_session_siswa (scanner_session_id, siswa_id)`. |

## 4. View baru

| View | Fungsi |
|---|---|
| `v_rombel_display` | Menyediakan display label rombel yang konsisten untuk backend/frontend. |
| `v_import_siswa_minimal_rows` | Memudahkan review baris import minimal dari mitra. |
| `v_presensi_session_rekap` | Rekap presensi berbasis sesi dan snapshot lokasi. |

## 5. Parser `KELAS` yang harus diikuti backend

Format minimal:

```text
^(10|11|12|13)\s+([A-Z0-9]+)(?:\s+(\d+))?$
```

Contoh hasil:

| Input | tingkatan | tingkat_angka | kode_jurusan | nomor_rombel | display_mode | display_label |
|---|---|---:|---|---:|---|---|
| `10 AKL` | X | 10 | AKL | 1 | tanpa_nomor | 10 AKL |
| `11 TKJ 2` | XI | 11 | TKJ | 2 | dengan_nomor | 11 TKJ 2 |
| `12 RPL` | XII | 12 | RPL | 1 | tanpa_nomor | 12 RPL |

## 6. Dampak ke backend

Backend wajib:

1. Menyimpan `NISN` sebagai string.
2. Tidak mewajibkan gender dan angkatan saat import.
3. Menyimpan `NO` ke `source_no`, bukan `no_absen`, kecuali `use_no_as_absen = 1`.
4. Menghasilkan `label_rombel = 10 AKL` untuk input `10 AKL`.
5. Mengisi `nomor_rombel = 1` hanya sebagai kebutuhan internal.
6. Mengisi `selected_rombel_label_snapshot` saat membuka sesi scanner.
7. Mengisi `lokasi_mode` dan snapshot lokasi saat sesi/presensi dibuat.

## 7. Dampak ke frontend

Frontend wajib:

1. Menampilkan rombel dari `display_label` atau `label_rombel`.
2. Tidak menampilkan `10 AKL 1` untuk rombel tunggal hasil import `10 AKL`.
3. Menyediakan opsi lokasi sesi: tidak dicatat, pilih master, input manual, fleksibel.
4. Tidak memaksa guru/operator memperbarui mapping ruangan setiap kelas berpindah.

## 8. File yang dihasilkan

| File | Fungsi |
|---|---|
| `prototype-db-3.8.sql` | Skema penuh berbasis 3.7 + patch 3.8. |
| `prototype-db-3.7-to-3.8-migration.sql` | Patch upgrade dari DB 3.7 ke DB 3.8. |
| `prototype-db-3.8-rollback.sql` | Rollback struktural dari DB 3.8 ke DB 3.7. |
| `prototype-db-3.8-changes.md` | Dokumentasi perubahan. |
| `README_DB_3.8.md` | Panduan penerapan dan validasi. |

## 9. Catatan risiko

Rollback `siswa.jenis_kelamin` dan `siswa.angkatan` ke `NOT NULL` dapat gagal jika sudah ada data NULL dari import mitra. Kegagalan tersebut lebih aman daripada membuat data palsu. Admin harus memutuskan pengisian data secara sadar apabila benar-benar ingin kembali ke aturan DB 3.7.
