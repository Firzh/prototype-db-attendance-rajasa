# Implementasi Backend untuk `proto-db-3.5`

Dokumen ini menjelaskan rancangan implementasi backend berdasarkan struktur `proto-db-3.5.sql`. Fokus utama: field otomatis, rombel, plotting rombel-ruangan, penempatan siswa, import wizard, export laporan presensi, notifikasi berbasis permission, wali kelas, dan modul nilai/import.

Dokumen ini tidak mengubah database. Isinya adalah pedoman implementasi service, endpoint, validasi, transaksi, dan job backend.

---

## 1. Prinsip Umum Backend

Backend harus menjadi pusat logika bisnis. Database berfungsi sebagai penjaga integritas data melalui `FOREIGN KEY`, `UNIQUE`, `CHECK`, `DEFAULT`, `VIEW`, `TRIGGER`, dan `STORED PROCEDURE` tertentu.

Pembagian tanggung jawab:

| Area | Ditangani oleh |
|---|---|
| `AUTO_INCREMENT`, `created_at`, `updated_at`, default status | Database |
| Validasi relasi, unique, check nilai | Database + Backend |
| Generate `kode_jurusan`, `label_rombel`, `kode_ruangan`, `nama_ruangan` | Backend |
| Update cache siswa aktif | Backend |
| Parser import dan mapping kolom | Backend, dibantu frontend preview jika perlu |
| Notifikasi berbasis permission | Backend |
| Resolve notifikasi otomatis | Backend scheduler/job |
| Export presensi | Backend |
| Modal/popup UI | Frontend, memanggil endpoint backend |

Prinsip penting:

```text
Database menjaga data tidak rusak.
Backend menentukan proses bisnis.
Frontend hanya membantu input, preview, konfirmasi, dan pengalaman pengguna.
```

---

## 2. Pola Struktur Backend yang Disarankan

Gunakan pola berlapis agar logika tidak tercecer di controller.

```text
Controller
  ↓
Request Validator / DTO
  ↓
Service
  ↓
Repository / Query Builder
  ↓
Database
```

Contoh struktur folder generik:

```text
app/
  Controllers/
    JurusanController.php
    RombelController.php
    PlottingRombelController.php
    PenempatanSiswaController.php
    ImportController.php
    NotificationController.php
    ExportController.php
    WaliKelasController.php
  Services/
    JurusanService.php
    RombelService.php
    RuanganService.php
    PlottingRombelService.php
    PenempatanSiswaService.php
    ImportDetectionService.php
    ImportMappingService.php
    ImportExecutionService.php
    NotificationService.php
    NotificationTargetResolver.php
    PresensiExportService.php
    PermissionService.php
  Repositories/
    JurusanRepository.php
    RombelRepository.php
    SiswaRepository.php
    ImportRepository.php
    NotificationRepository.php
  Jobs/
    ProcessImportJob.php
    GenerateNotificationDigestJob.php
    ResolveNotificationJob.php
    ExportPresensiJob.php
  Support/
    AcademicPeriodResolver.php
    CodeGenerator.php
    ImportHeaderNormalizer.php
    SpreadsheetParser.php
```

Jika backend masih sederhana, repository boleh dilewati. Namun service layer tetap perlu agar controller tidak menjadi tempat semua logika.

---

## 3. Middleware Permission

Karena `proto-db-3.5` sudah memakai konsep `roles`, `permissions`, `policies`, `user_permissions`, dan relasi sejenisnya, semua endpoint penting harus memakai pemeriksaan permission.

Contoh permission minimal:

| Endpoint/Modul | Permission minimal |
|---|---|
| Kelola jurusan/rombel/plotting | `academic.write` |
| Baca akademik/rombel | `academic.read` |
| Kelola siswa/penempatan | `students.write` |
| Import data | `import.write` |
| Lihat riwayat import | `import.read` |
| Import/kelola nilai | `grades.write` |
| Baca nilai | `grades.read` |
| Export laporan presensi | `reports.export` |
| Kelola notifikasi global | `notifications.write` |
| Baca notifikasi | `notifications.read` |
| Validasi presensi | `attendance.validate` |

Pseudocode:

```php
function authorize(string $permissionSlug, int $userId): void
{
    if (!$permissionService->userCan($userId, $permissionSlug)) {
        throw new AuthorizationException('Anda tidak memiliki wewenang untuk aksi ini.');
    }
}
```

Catatan: notifikasi operasional juga harus mengikuti permission. User tanpa permission terkait tidak perlu menerima notifikasi terkait modul tersebut.

---

## 4. Konfigurasi Akademik Aktif

`proto-db-3.5` menambahkan konfigurasi:

```text
academic.tahun_ajaran_aktif
academic.semester_aktif
module.exams.enabled
import.default_backend_parser
plotting.max_rombel_per_ruang_kelas
```

Backend perlu membuat helper:

```php
class AcademicPeriodResolver
{
    public function getActiveYear(): string;
    public function getActiveSemester(): string;
    public function resolve(?string $tahunAjaran, ?string $semester): array;
}
```

Aturan:

1. Jika request mengirim `tahun_ajaran` dan `semester`, gunakan nilai request.
2. Jika kosong, ambil dari tabel `konfigurasi`.
3. Jika konfigurasi kosong, tolak proses yang membutuhkan periode akademik.

Contoh error:

```json
{
  "success": false,
  "message": "Tahun ajaran aktif belum dikonfigurasi."
}
```

---

## 5. Field Otomatis / Otonom

### 5.1. Generate Kode Jurusan

Input admin:

```text
nama_jurusan
ketua_jurusan
```

Backend generate:

```text
kode_jurusan
status = aktif
```

Algoritma dasar:

```php
function generateKodeJurusan(string $namaJurusan): string
{
    $words = preg_split('/\s+/', trim($namaJurusan));
    $code = '';

    foreach ($words as $word) {
        if ($word !== '') {
            $code .= mb_strtoupper(mb_substr($word, 0, 1));
        }
    }

    return $code;
}
```

Contoh:

| Nama Jurusan | Kode |
|---|---|
| Teknik Kerja Jaringan | TKJ |
| Teknik Instalasi Tenaga Listrik | TITL |
| Teknik Kendaraan Ringan | TKR |

Validasi:

1. `nama_jurusan` wajib.
2. `kode_jurusan` hasil generate harus unik.
3. Jika bentrok, backend boleh menawarkan opsi manual atau suffix.

Strategi bentrok:

```text
TKJ sudah dipakai.
Backend menyarankan: TKJ2.
Admin tetap boleh override kode sebelum simpan.
```

Database tetap menjadi penjaga terakhir melalui `UNIQUE kode_jurusan`.

---

### 5.2. Generate Label Rombel

Tabel target:

```text
rombel
```

Input minimal:

```text
tingkatan
jurusan_id
jumlah_rombel
```

Backend generate:

```text
nomor_rombel
label_rombel
status = aktif
```

Rumus:

```text
label_rombel = tingkatan + '-' + kode_jurusan + '-' + nomor_rombel
```

Contoh:

```text
X + TKJ + 1 = X-TKJ-1
X + TKJ + 2 = X-TKJ-2
```

Pseudocode bulk create:

```php
DB::transaction(function () use ($tingkatan, $jurusanId, $jumlah) {
    $jurusan = $jurusanRepo->findOrFail($jurusanId);

    $lastNumber = $rombelRepo->maxNomorRombel($tingkatan, $jurusanId);

    for ($i = 1; $i <= $jumlah; $i++) {
        $nomor = $lastNumber + $i;
        $label = "{$tingkatan}-{$jurusan->kode_jurusan}-{$nomor}";

        $rombelRepo->create([
            'tingkatan' => $tingkatan,
            'jurusan_id' => $jurusanId,
            'nomor_rombel' => $nomor,
            'label_rombel' => $label,
            'status' => 'aktif',
        ]);
    }
});
```

Validasi:

1. `tingkatan` wajib dan sesuai enum/opsi sistem.
2. `jurusan_id` harus valid.
3. `jumlah_rombel` minimal 1.
4. Jangan membuat label duplikat.

---

### 5.3. Generate Nama Ruangan Buffer

Tabel terkait:

```text
ruangan
jurusan_ruangan_buffer
```

`proto-db-3.5` menyediakan stored procedure:

```sql
sp_upsert_jurusan_ruangan_buffer(
  p_jurusan_id,
  p_ruangan_id,
  p_jenis_ruangan,
  p_status
)
```

Backend tetap menjadi pemanggil utama.

Alur:

```text
1. Backend membuat/menentukan data ruangan di tabel ruangan.
2. Backend memanggil sp_upsert_jurusan_ruangan_buffer.
3. Procedure mengisi/memperbarui jurusan_ruangan_buffer.
```

Contoh:

```php
DB::statement('CALL sp_upsert_jurusan_ruangan_buffer(?, ?, ?, ?)', [
    $jurusanId,
    $ruanganId,
    'lab',
    'aktif',
]);
```

Nama ruangan yang terbentuk:

```text
Lab TKJ 1
Kelas TKJ 1
Kantor TKJ 1
```

Catatan:

- `jurusan_ruangan_buffer` jangan diisi manual oleh user.
- UI cukup menampilkan hasilnya.
- Jika nama perlu diedit manual, buat fitur override terkontrol, jangan langsung bebas sejak awal.

---

## 6. Modul Wali Kelas

Tabel baru:

```text
rombel_wali_kelas
```

Fungsi:

```text
Menghubungkan guru/staff sebagai wali kelas resmi dengan rombel pada tahun ajaran dan semester tertentu.
```

Relasi:

```text
rombel_wali_kelas.rombel_id -> rombel.rombel_id
rombel_wali_kelas.guru_id -> guru_staff.guru_id
```

Jangan menggunakan:

```text
plotting_rombel.user_id
```

sebagai wali kelas, karena `plotting_rombel.user_id` bermakna penanggung jawab operasional/PIC/pengawas ruangan.

### Endpoint

```http
GET    /api/rombel/{rombel_id}/wali-kelas
POST   /api/rombel/{rombel_id}/wali-kelas
PATCH  /api/rombel-wali-kelas/{wali_kelas_id}
DELETE /api/rombel-wali-kelas/{wali_kelas_id}
```

### Request Create

```json
{
  "guru_id": 5,
  "tahun_ajaran": "2025/2026",
  "semester": "ganjil",
  "tanggal_mulai": "2025-07-15"
}
```

### Validasi

1. `rombel_id` harus valid.
2. `guru_id` harus valid dan status guru aktif.
3. Satu rombel hanya boleh memiliki satu wali kelas aktif pada periode yang sama.
4. Jika ingin ganti wali kelas, nonaktifkan penugasan lama terlebih dahulu atau lakukan proses replace dalam transaksi.

### Replace Wali Kelas

```php
DB::transaction(function () use ($rombelId, $guruId, $tahunAjaran, $semester) {
    $waliRepo->nonaktifkanWaliAktif($rombelId, $tahunAjaran, $semester, now()->toDateString());

    $waliRepo->create([
        'rombel_id' => $rombelId,
        'guru_id' => $guruId,
        'tahun_ajaran' => $tahunAjaran,
        'semester' => $semester,
        'tanggal_mulai' => now()->toDateString(),
        'status' => 'aktif',
    ]);
});
```

View pendukung:

```text
v_rombel_wali_kelas_aktif
```

Gunakan view ini untuk tampilan daftar rombel + wali kelas aktif.

---

## 7. Modul Plotting Rombel-Ruangan

Tabel utama:

```text
plotting_rombel
```

Field penting:

```text
rombel_id
ruangan_id
tahun_ajaran
semester
user_id
jam_pulang_default
status
```

Makna `user_id`:

```text
Penanggung jawab operasional / guru pengawas / PIC ruangan.
Boleh NULL.
Bukan wali kelas resmi.
```

### Endpoint

```http
GET    /api/plotting-rombel
POST   /api/plotting-rombel
PATCH  /api/plotting-rombel/{plotting_id}
DELETE /api/plotting-rombel/{plotting_id}
```

### Request Create

```json
{
  "rombel_id": 10,
  "ruangan_id": 4,
  "tahun_ajaran": "2025/2026",
  "semester": "ganjil",
  "user_id": null,
  "jam_pulang_default": "15:00:00"
}
```

### Validasi Backend

1. `rombel_id` valid dan aktif.
2. `ruangan_id` valid.
3. `tahun_ajaran` dan `semester` valid.
4. `user_id` opsional. Jika diisi, harus mengarah ke user valid.
5. Untuk `jenis_ruangan = kelas`, maksimal 2 rombel aktif per ruangan/periode.
6. Cek konflik rombel sudah diplotting pada periode yang sama jika aturan bisnis menginginkan satu rombel hanya punya satu ruangan utama.

Database sudah punya trigger:

```text
trg_plotting_rombel_bi_max2_kelas
trg_plotting_rombel_bu_max2_kelas
```

Trigger ini menjadi guardrail terakhir untuk batas maksimal 2 rombel pada ruangan jenis kelas.

Backend tetap perlu validasi lebih awal agar pesan UI lebih rapi.

### Query Cek Jumlah Rombel pada Ruangan

```sql
SELECT COUNT(DISTINCT pr.rombel_id) AS total_rombel
FROM plotting_rombel pr
JOIN jurusan_ruangan_buffer jrb ON jrb.ruangan_id = pr.ruangan_id
WHERE pr.ruangan_id = :ruangan_id
  AND pr.tahun_ajaran = :tahun_ajaran
  AND pr.semester = :semester
  AND pr.status = 'aktif'
  AND jrb.jenis_ruangan = 'kelas'
  AND jrb.status = 'aktif';
```

Jika `total_rombel >= 2`, tolak insert/update.

### View Pendukung

```text
v_plotting_rombel_kloter
v_rombel_plotting_status_aktif
v_dashboard_plotting_rombel
```

Gunakan untuk:

- menampilkan kloter otomatis;
- melihat rombel yang sudah/belum diplotting;
- dashboard persentase plotting.

---

## 8. Modul Penempatan Siswa

Tabel utama:

```text
penempatan_siswa_rombel
siswa
rombel
jurusan
```

Sumber resmi histori penempatan adalah:

```text
penempatan_siswa_rombel
```

Cache aktif berada di:

```text
siswa.jurusan_id_aktif
siswa.rombel_id_aktif
siswa.kelas_aktif
```

Cache harus diperbarui oleh backend setiap kali penempatan aktif berubah.

### Endpoint

```http
GET    /api/penempatan-siswa
POST   /api/penempatan-siswa
PATCH  /api/penempatan-siswa/{penempatan_id}
DELETE /api/penempatan-siswa/{penempatan_id}
POST   /api/penempatan-siswa/bulk
POST   /api/penempatan-siswa/{siswa_id}/pindah-rombel
```

### Request Create

```json
{
  "siswa_id": 1001,
  "rombel_id": 10,
  "tahun_ajaran": "2025/2026",
  "semester": "ganjil",
  "no_absen": 17,
  "tanggal_mulai": "2025-07-15"
}
```

### Validasi

1. `siswa_id` valid dan aktif.
2. `rombel_id` valid dan aktif.
3. `tahun_ajaran` dan `semester` valid.
4. `no_absen` tidak boleh dobel dalam rombel/periode aktif.
5. Siswa tidak boleh punya dua penempatan aktif pada periode yang sama kecuali proses pindah rombel menonaktifkan data lama.

Database `proto-db-3.5` sudah menambahkan unique helper untuk `no_absen` aktif:

```text
uk_penempatan_no_absen_aktif
```

Backend tetap wajib validasi sebelum insert agar error lebih ramah.

### Proses Pindah Rombel

```php
DB::transaction(function () use ($siswaId, $rombelBaruId, $tahunAjaran, $semester, $noAbsen) {
    $penempatanRepo->nonaktifkanPenempatanAktif($siswaId, $tahunAjaran, $semester, now()->toDateString());

    $penempatan = $penempatanRepo->create([
        'siswa_id' => $siswaId,
        'rombel_id' => $rombelBaruId,
        'tahun_ajaran' => $tahunAjaran,
        'semester' => $semester,
        'no_absen' => $noAbsen,
        'tanggal_mulai' => now()->toDateString(),
        'is_aktif' => 1,
    ]);

    $this->syncSiswaCacheAktif($siswaId, $rombelBaruId);
});
```

### Sync Cache Siswa Aktif

```php
function syncSiswaCacheAktif(int $siswaId, int $rombelId): void
{
    $rombel = $rombelRepo->findWithJurusan($rombelId);

    $siswaRepo->update($siswaId, [
        'jurusan_id_aktif' => $rombel->jurusan_id,
        'rombel_id_aktif' => $rombel->rombel_id,
        'kelas_aktif' => $rombel->label_rombel,
    ]);
}
```

---

## 9. Import Wizard

Tabel:

```text
import_jobs
import_column_mappings
import_row_logs
```

Jenis import utama:

```text
master_siswa
siswa_penempatan_rombel
nilai_akademik
```

Ada juga `update_penempatan_rombel` di DB. Secara UI, ini sebaiknya menjadi mode di dalam `siswa_penempatan_rombel`, bukan menu utama terpisah.

### Alur Import Wizard

```text
1. Upload file
2. Backend membaca sample file
3. Backend mendeteksi jenis import
4. Backend membuat auto-mapping kolom
5. User mengonfirmasi mapping
6. Backend validasi seluruh baris
7. User melihat preview error/warning
8. User mengeksekusi import
9. Backend menjalankan transaksi/batch import
10. Backend membuat ringkasan hasil dan notifikasi jika perlu
```

### Endpoint

```http
POST /api/imports/upload
GET  /api/imports/{import_id}
POST /api/imports/{import_id}/detect
GET  /api/imports/{import_id}/mappings
PUT  /api/imports/{import_id}/mappings
POST /api/imports/{import_id}/validate
POST /api/imports/{import_id}/execute
GET  /api/imports/{import_id}/row-logs
GET  /api/imports/{import_id}/error-report
POST /api/imports/{import_id}/cancel
```

### Backend Parser

Rekomendasi:

```text
Backend final parser: FastExcelReader atau OpenSpout
Frontend preview CSV: Papa Parse, opsional
Frontend preview XLSX: read-excel-file, opsional
```

Untuk MVP, cukup parser backend.

`import_jobs.parser_engine` mendukung:

```text
openspout
fastexcelreader
papaparse
read_excel_file
manual
other
```

Backend boleh menyimpan nilai sesuai engine aktual. Jika memakai FastExcelReader, isi:

```text
fastexcelreader
```

---

## 10. Deteksi Jenis Import

Backend membaca header dan beberapa baris pertama. Sistem memberi skor.

### Rule Deteksi

#### Master Siswa

Indikator header:

```text
nisn
nis
nama
nama lengkap
nama peserta didik
jenis kelamin
jk
angkatan
```

Skor tinggi jika ada:

```text
nisn + nama + jenis kelamin
```

#### Siswa + Penempatan Rombel

Indikator header:

```text
nisn
nama
kelas
rombel
jurusan
kode jurusan
program keahlian
no absen
tingkat
nomor rombel
```

Skor tinggi jika ada:

```text
nisn + nama + kelas/rombel + jurusan/no_absen
```

#### Nilai Akademik

Indikator header:

```text
nisn
nama
mapel
kode mapel
nama mapel
nilai
jenis penilaian
semester
tahun ajaran
```

Skor tinggi jika ada:

```text
nisn + mapel + nilai
```

### Output Deteksi

```json
{
  "detected_type": "siswa_penempatan_rombel",
  "confidence": 91.25,
  "alternatives": [
    {"type": "master_siswa", "confidence": 68.00},
    {"type": "nilai_akademik", "confidence": 12.00}
  ]
}
```

Jika confidence kurang dari ambang batas, misalnya 80, frontend meminta user memilih jenis import.

---

## 11. Mapping Kolom Import

Mapping kolom berarti mencocokkan header file dengan field sistem.

Contoh file:

```text
Nama Peserta Didik | NIS Nasional | JK | Kelas | Program Keahlian | No
```

Target sistem:

```text
siswa.nama_lengkap
siswa.nisn
siswa.jenis_kelamin
rombel.label_rombel
jurusan.kode_jurusan
penempatan_siswa_rombel.no_absen
```

### Alias Header

Backend perlu memiliki kamus alias:

```php
$aliases = [
    'siswa.nama_lengkap' => [
        'nama', 'nama siswa', 'nama lengkap', 'nama peserta didik'
    ],
    'siswa.nisn' => [
        'nisn', 'nis nasional', 'nomor induk siswa nasional'
    ],
    'siswa.nis' => [
        'nis', 'nis sekolah', 'nomor induk siswa'
    ],
    'siswa.jenis_kelamin' => [
        'jk', 'jenis kelamin', 'gender'
    ],
    'jurusan.kode_jurusan' => [
        'jurusan', 'kode jurusan', 'program keahlian', 'kompetensi keahlian'
    ],
    'rombel.label_rombel' => [
        'kelas', 'rombel', 'kelas/rombel', 'nama rombel'
    ],
    'penempatan_siswa_rombel.no_absen' => [
        'no', 'no absen', 'nomor absen', 'nomor urut'
    ],
    'nilai_akademik.nilai' => [
        'nilai', 'skor', 'angka nilai'
    ],
    'mata_pelajaran.kode_mapel' => [
        'kode mapel', 'kode mata pelajaran'
    ],
    'mata_pelajaran.nama_mapel' => [
        'mapel', 'mata pelajaran', 'nama mapel'
    ],
];
```

### Normalisasi Header

```php
function normalizeHeader(string $header): string
{
    $header = mb_strtolower(trim($header));
    $header = preg_replace('/[^a-z0-9\s_\-]/u', ' ', $header);
    $header = preg_replace('/\s+/', ' ', $header);
    return trim($header);
}
```

### Simpan Mapping

Setelah auto-mapping, simpan ke:

```text
import_column_mappings
```

Field penting:

```text
source_column_index
source_column_name
sample_value
target_field
confidence
is_required
is_confirmed
```

Mapping belum boleh dieksekusi sampai required fields terisi dan mapping dikonfirmasi.

---

## 12. Validasi Import per Jenis

### 12.1. Import Master Siswa

Target:

```text
siswa
profil_siswa
users opsional
```

Required minimal:

```text
siswa.nisn
siswa.nama_lengkap
siswa.jenis_kelamin
```

Validasi:

1. `nisn` wajib.
2. `nisn` unik per siswa.
3. `nis` jika ada tidak boleh konflik dengan siswa lain.
4. `jenis_kelamin` hanya `L` atau `P`.
5. `angkatan` berupa tahun valid.
6. Email jika ada harus valid dan tidak konflik.

Proses:

```text
Jika NISN belum ada: insert siswa.
Jika NISN sudah ada: update field yang diizinkan.
Jika profil ada: insert/update profil_siswa.
```

Jangan mengubah:

```text
siswa.jurusan_id_aktif
siswa.rombel_id_aktif
siswa.kelas_aktif
penempatan_siswa_rombel
```

---

### 12.2. Import Siswa + Penempatan Rombel

Target:

```text
siswa
penempatan_siswa_rombel
update cache siswa
```

Required minimal:

```text
siswa.nisn
siswa.nama_lengkap
rombel.label_rombel atau kombinasi tingkatan + jurusan + nomor_rombel
```

Opsional tetapi disarankan:

```text
no_absen
jenis_kelamin
nis
tahun_ajaran
semester
```

Jika `tahun_ajaran` atau `semester` tidak ada dalam file, gunakan konfigurasi aktif.

Validasi:

1. Siswa valid atau bisa dibuat.
2. Jurusan harus ditemukan.
3. Rombel harus ditemukan.
4. Jangan auto-create rombel karena typo file.
5. No absen tidak boleh dobel dalam rombel/periode aktif.
6. Jika siswa sudah punya penempatan aktif pada periode sama, proses tergantung opsi.

Opsi konflik:

```json
{
  "placement_mode": "skip_conflict | move_existing | overwrite_active | mark_conflict"
}
```

Rekomendasi default:

```text
mark_conflict
```

Agar sistem tidak diam-diam memindahkan siswa.

Proses berhasil:

```text
1. Insert/update siswa.
2. Insert penempatan_siswa_rombel.
3. Nonaktifkan penempatan lama jika mode pindah.
4. Update siswa.jurusan_id_aktif.
5. Update siswa.rombel_id_aktif.
6. Update siswa.kelas_aktif.
```

---

### 12.3. Import Nilai Akademik

Target:

```text
nilai_akademik
```

Tabel referensi:

```text
siswa
mata_pelajaran
guru_staff opsional
```

Required minimal:

```text
siswa.nisn atau siswa.nis
mata_pelajaran.kode_mapel atau nama_mapel
nilai_akademik.nilai
nilai_akademik.jenis_penilaian
nilai_akademik.tahun_ajaran
nilai_akademik.semester
```

Jenis penilaian yang didukung DB:

```text
tugas
kuis
praktik
uts
uas
akhir
lainnya
```

Validasi:

1. Siswa harus ditemukan.
2. Mata pelajaran harus ditemukan.
3. Jangan auto-create mata pelajaran dari file nilai.
4. Nilai harus 0 sampai 100.
5. Tahun ajaran dan semester valid.
6. Jenis penilaian sesuai enum.

Jika mapel typo:

```text
Matematik
```

Jangan auto-create. Tampilkan error:

```text
Mapel "Matematik" tidak ditemukan. Pilih mapel yang benar atau perbaiki file.
```

---

## 13. Eksekusi Import

Gunakan batch + transaksi per chunk, bukan satu transaksi besar untuk seluruh file besar.

Rekomendasi:

```text
chunk size: 200-500 baris
```

Pseudocode:

```php
function executeImport(int $importId): void
{
    $job = $importRepo->findOrFail($importId);
    $mappings = $importRepo->getConfirmedMappings($importId);

    $importRepo->markProcessing($importId);

    foreach ($parser->rows($job->file_path) as $chunk) {
        DB::transaction(function () use ($chunk, $job, $mappings) {
            foreach ($chunk as $row) {
                try {
                    $normalized = $normalizer->normalize($row, $mappings);
                    $result = $this->processRowByType($job->import_type, $normalized, $job->options_json);

                    $importRepo->logRowImported($job->import_id, $row, $normalized, $result);
                } catch (ValidationException $e) {
                    $importRepo->logRowError($job->import_id, $row, $e->getMessage());
                }
            }
        });
    }

    $importRepo->refreshSummary($importId);
    $this->createImportNotificationIfNeeded($importId);
}
```

Status akhir:

```text
success
partial_failed
failed
cancelled
```

Gunakan `partial_failed` jika ada baris gagal tetapi sebagian data berhasil masuk.

---

## 14. Export Laporan Presensi

Export memakai popup/multi-step di frontend, tetapi backend tetap menyediakan endpoint.

Alur UI:

```text
Step 1: pilih tanggal mulai, tanggal berakhir, dan filter.
Step 2: pilih format export dan lihat ringkasan.
```

Endpoint:

```http
POST /api/reports/presensi/export/preview
POST /api/reports/presensi/export
GET  /api/reports/exports/{export_id}/download
```

### Filter

```json
{
  "tanggal_mulai": "2026-07-01",
  "tanggal_berakhir": "2026-07-31",
  "jurusan_id": 1,
  "rombel_id": 10,
  "ruangan_id": null,
  "status": null,
  "validasi": "valid",
  "tahun_ajaran": "2025/2026",
  "semester": "ganjil"
}
```

### Format

```text
xlsx
csv
pdf
```

Gunakan view:

```text
v_presensi_detail
```

karena view ini sudah membawa data siswa, rombel, jurusan, ruangan, status, validasi, dan waktu presensi.

### Validasi Export

1. `tanggal_mulai` wajib.
2. `tanggal_berakhir` wajib.
3. `tanggal_mulai <= tanggal_berakhir`.
4. Batasi PDF, misalnya maksimal 31 hari atau maksimal 2.000 baris.
5. XLSX/CSV boleh lebih besar, tetapi tetap perlu limit dan job async jika data besar.
6. User harus punya `reports.export`.

### Preview Response

```json
{
  "total_rows": 624,
  "periode": "2026-07-01 s.d. 2026-07-31",
  "filters": {
    "jurusan": "TKJ",
    "rombel": "X-TKJ-1",
    "validasi": "valid"
  },
  "recommended_formats": ["xlsx", "csv", "pdf"]
}
```

Jika terlalu besar untuk PDF:

```json
{
  "total_rows": 18000,
  "warnings": [
    "PDF tidak disarankan untuk data lebih dari 2000 baris. Gunakan XLSX/CSV atau persempit filter."
  ]
}
```

---

## 15. Notifikasi Generik

Tabel baru:

```text
notification_rules
notifikasi
notifikasi_penerima
user_notification_preferences
```

Tabel legacy:

```text
notifikasi_admin
```

tetap dipertahankan untuk kompatibilitas lama. Pengembangan baru sebaiknya memakai model generik.

### Konsep Penting

```text
notifikasi = event/masalah utama
notifikasi_penerima = daftar user yang menerima event tersebut
user_notification_preferences = preferensi pribadi user
notification_rules = aturan default event
```

Bedakan:

```text
is_read = user sudah membaca
is_resolved = masalah sudah selesai
```

### Endpoint Notifikasi

```http
GET   /api/notifications
GET   /api/notifications/unread-count
POST  /api/notifications/{notif_id}/read
POST  /api/notifications/read-all
POST  /api/notifications/{notif_id}/resolve
GET   /api/notification-preferences
PUT   /api/notification-preferences
GET   /api/admin/notification-rules
PUT   /api/admin/notification-rules/{rule_id}
```

### Membuat Notifikasi

Pseudocode:

```php
function createEventNotification(string $eventKey, array $payload): void
{
    $rule = $notificationRuleRepo->findActiveByEventKey($eventKey);

    if (!$rule) {
        return;
    }

    $notif = $notificationRepo->upsertOpenNotification([
        'rule_id' => $rule->rule_id,
        'event_key' => $eventKey,
        'module_name' => $rule->module_name,
        'entity_type' => $payload['entity_type'] ?? $rule->entity_type,
        'entity_id' => $payload['entity_id'] ?? null,
        'pesan' => $payload['pesan'],
        'level_notif' => $payload['level_notif'] ?? $rule->default_level_notif,
        'required_perm_slug' => $rule->required_perm_slug,
        'target_role_slug' => $rule->target_role_slug,
        'frequency' => $rule->default_frequency,
        'is_resolved' => 0,
    ]);

    $users = $targetResolver->resolveRecipients($rule, $payload);

    foreach ($users as $user) {
        if ($preferenceService->shouldDeliver($user->user_id, $rule, $notif)) {
            $notificationRepo->addRecipient($notif->notif_id, $user->user_id, 'inbox');
        }
    }
}
```

### Target Resolver

Target user ditentukan oleh:

1. `required_perm_slug`.
2. `target_role_slug` jika ada.
3. resource scope jika nanti diterapkan.
4. preferensi user.
5. critical lock.

Prinsip:

```text
User hanya menerima notifikasi jika punya wewenang terhadap modul tersebut.
```

Contoh:

```text
plotting_incomplete -> required_perm_slug = academic.write
student_import_partial_failed -> required_perm_slug = import.write
attendance_online_pending_review -> required_perm_slug = attendance.online_review
```

Intern/read-only tidak menerima notifikasi aksi yang tidak bisa dia tindak lanjuti.

---

## 16. Notifikasi yang Perlu Dibuat Backend

### 16.1. Rombel Belum Diplotting

Event:

```text
plotting_incomplete
```

Sumber query:

```text
v_dashboard_plotting_rombel
atau v_rombel_plotting_status_aktif
```

Kondisi:

```text
jumlah_rombel_belum_diplotting > 0
```

Pesan:

```text
Ada {n} rombel aktif yang belum diplotting pada semester {semester} {tahun_ajaran}.
```

Resolved otomatis jika:

```text
jumlah_rombel_belum_diplotting = 0
```

Frekuensi:

```text
daily
```

### 16.2. Siswa Aktif Belum Punya Rombel

Event:

```text
student_without_rombel
```

Kondisi:

```text
siswa.status = aktif AND siswa.rombel_id_aktif IS NULL
```

Target:

```text
students.write
```

Resolved otomatis jika semua siswa aktif sudah punya rombel aktif.

### 16.3. Import Sebagian Gagal

Event:

```text
student_import_partial_failed
grade_import_partial_failed
```

Kondisi:

```text
import_jobs.status = partial_failed OR error_rows > 0
```

Target:

```text
import.write atau grades.write
```

Resolved manual, karena operator perlu membaca error report.

### 16.4. Ruang Kelas Sudah Penuh Kloter

Event:

```text
room_class_slot_full
```

Kondisi:

```text
ruangan jenis kelas sudah dipakai 2 rombel aktif dalam periode yang sama
```

Target:

```text
academic.write
```

Resolved otomatis jika jumlah rombel aktif di ruangan/periode turun di bawah 2.

---

## 17. Scheduler / Background Job

Backend perlu scheduler untuk notifikasi computed.

Contoh job harian:

```text
DailyAcademicNotificationJob
```

Tugas:

1. Cek plotting incomplete.
2. Cek siswa aktif tanpa rombel.
3. Cek penempatan konflik.
4. Cek import unresolved.
5. Resolve notifikasi yang kondisinya sudah selesai.

Contoh jadwal:

```text
Setiap hari 07:00 waktu server/sekolah.
```

Pseudocode:

```php
class DailyAcademicNotificationJob
{
    public function handle(): void
    {
        $this->checkPlottingIncomplete();
        $this->checkStudentsWithoutRombel();
        $this->resolveFixedNotifications();
    }
}
```

Critical event dapat dibuat instant, tidak perlu menunggu scheduler.

---

## 18. Preferensi Notifikasi User

Tabel:

```text
user_notification_preferences
```

User boleh mengatur:

```text
frequency
popup_enabled
inbox_enabled
email_enabled
is_muted
```

Tetapi:

1. User hanya bisa mengatur preferensi untuk notifikasi yang memang berhak dia terima.
2. Critical notification tidak boleh benar-benar dimatikan.
3. Admin global mengatur `notification_rules`, user biasa hanya mengatur preferensi pribadi.

Validasi:

```php
if (!$permissionService->userCan($userId, $rule->required_perm_slug)) {
    throw new AuthorizationException('Anda tidak bisa mengatur notifikasi untuk modul yang bukan wewenang Anda.');
}
```

---

## 19. Modul Ujian Sementara Nonaktif

Konfigurasi:

```text
module.exams.enabled = false
```

Backend harus:

1. Menyembunyikan menu ujian di response menu/sidebar.
2. Menolak endpoint ujian jika modul tidak aktif.
3. Tidak menghapus tabel `sesi_ujian` dan `peserta_ujian`.
4. Tidak memakai `peserta_ujian.nilai` untuk nilai akademik reguler.

Pseudocode middleware:

```php
function ensureModuleEnabled(string $moduleKey): void
{
    if (!$configService->bool("module.{$moduleKey}.enabled")) {
        throw new ModuleDisabledException('Modul ini sedang dinonaktifkan.');
    }
}
```

---

## 20. Nilai Akademik dari Import

Tabel:

```text
nilai_akademik
mata_pelajaran
siswa
guru_staff
```

Backend harus memproses nilai melalui import wizard, bukan input manual massal.

Endpoint tambahan:

```http
GET /api/nilai-akademik
GET /api/nilai-akademik/siswa/{siswa_id}
POST /api/imports/upload   dengan import_type nilai_akademik
```

Validasi nilai:

```text
0 <= nilai <= 100
```

DB sudah punya `CHECK`, tetapi backend tetap harus menolak sebelum insert.

---

## 21. Response Format Standar

### Success

```json
{
  "success": true,
  "message": "Data berhasil disimpan.",
  "data": {}
}
```

### Validation Error

```json
{
  "success": false,
  "message": "Data tidak valid.",
  "errors": {
    "nisn": ["NISN wajib diisi."],
    "rombel_id": ["Rombel tidak ditemukan."]
  }
}
```

### Business Rule Error

```json
{
  "success": false,
  "message": "Ruangan ini sudah dipakai oleh 2 rombel pada semester ini. Pilih ruangan lain atau nonaktifkan salah satu plotting.",
  "code": "ROOM_CLASS_SLOT_FULL"
}
```

### Authorization Error

```json
{
  "success": false,
  "message": "Anda tidak memiliki wewenang untuk aksi ini.",
  "code": "FORBIDDEN"
}
```

---

## 22. Audit dan Log Aktivitas

Setiap aksi penting harus masuk log aktivitas jika sistem sudah memiliki tabel audit/activity.

Minimal log untuk:

```text
buat/edit/hapus jurusan
buat/edit/hapus rombel
plotting rombel
ubah wali kelas
penempatan/pindah siswa
import data
export laporan
ubah rule notifikasi
resolve notifikasi
```

Payload log sebaiknya menyimpan:

```text
user_id
action
module
entity_type
entity_id
before_json
after_json
ip_address
user_agent
created_at
```

Jika tabel audit belum ada, gunakan log file backend sementara. Namun untuk produksi, lebih baik log tersimpan di DB.

---

## 23. Checklist Testing Backend

### Jurusan

- [ ] Generate kode jurusan dari nama.
- [ ] Tangani kode bentrok.
- [ ] Status default aktif.
- [ ] Update nama jurusan tidak merusak data rombel lama tanpa keputusan eksplisit.

### Rombel

- [ ] Bulk create rombel.
- [ ] Label otomatis benar.
- [ ] Tidak membuat duplikat label.
- [ ] Status aktif/nonaktif bekerja.

### Wali Kelas

- [ ] Satu rombel hanya punya satu wali aktif per periode.
- [ ] Ganti wali menonaktifkan data lama.
- [ ] View wali kelas aktif menampilkan data benar.

### Plotting

- [ ] Penanggung jawab boleh kosong.
- [ ] Satu ruang jenis kelas maksimal 2 rombel aktif per periode.
- [ ] Trigger DB menangkap pelanggaran jika backend luput.
- [ ] Kloter otomatis tampil benar.

### Penempatan Siswa

- [ ] Siswa bisa ditempatkan ke rombel.
- [ ] Cache siswa aktif tersinkron.
- [ ] Pindah rombel menonaktifkan penempatan lama.
- [ ] No absen tidak dobel.

### Import

- [ ] Parser membaca CSV/XLSX.
- [ ] Deteksi jenis import berjalan.
- [ ] Mapping kolom bisa dikoreksi.
- [ ] Error row tersimpan.
- [ ] Import partial_failed membuat notifikasi.
- [ ] Nilai tidak menerima angka di luar 0-100.

### Export

- [ ] Preview jumlah baris benar.
- [ ] XLSX/CSV/PDF bisa dihasilkan.
- [ ] PDF dibatasi untuk data besar.
- [ ] User tanpa `reports.export` ditolak.

### Notifikasi

- [ ] Notifikasi hanya dikirim ke user berpermission.
- [ ] `is_read` tidak mengubah `is_resolved`.
- [ ] Resolve otomatis bekerja untuk kondisi computed.
- [ ] Critical tidak bisa dimute penuh.
- [ ] Preferensi user tidak membuka akses ke modul lain.

---

## 24. Urutan Implementasi yang Disarankan

Tahap 1 — Fondasi:

```text
PermissionService
ConfigService
AcademicPeriodResolver
CodeGenerator
Response format standar
```

Tahap 2 — Akademik inti:

```text
JurusanService
RombelService
WaliKelasService
RuanganService
PlottingRombelService
PenempatanSiswaService
```

Tahap 3 — Import wizard:

```text
SpreadsheetParser
ImportDetectionService
ImportMappingService
ImportValidationService
ImportExecutionService
```

Tahap 4 — Notifikasi:

```text
NotificationRuleService
NotificationService
NotificationTargetResolver
NotificationPreferenceService
DailyAcademicNotificationJob
```

Tahap 5 — Export:

```text
PresensiExportService
Export preview
Export XLSX/CSV/PDF
```

Tahap 6 — Hardening:

```text
Audit log
Error report download
Retry import
Queue/job untuk import/export besar
Dashboard warning
```

---

## 25. Catatan Desain Penting

1. `plotting_rombel.user_id` adalah penanggung jawab operasional, bukan wali kelas.
2. Wali kelas resmi memakai `rombel_wali_kelas`.
3. Penempatan siswa resmi ada di `penempatan_siswa_rombel`; field aktif di `siswa` hanya cache.
4. Import otomatis boleh dilakukan dari dokumen administrasi, tetapi tetap harus punya mapping dan preview error.
5. Parser boleh pintar, tetapi tidak boleh langsung dipercaya tanpa validasi backend.
6. Notifikasi harus berbasis permission, bukan broadcast ke semua user.
7. `read` dan `resolved` pada notifikasi harus dipisahkan.
8. Export boleh memakai popup ringan di UI, tetapi backend tetap harus membatasi query.
9. Modul ujian cukup dinonaktifkan lewat konfigurasi, tabelnya jangan dihapus.
10. Nilai akademik masuk melalui import ke `nilai_akademik`, bukan melalui tabel ujian.

---

## 26. Definisi MVP Minimum

Jika ingin versi awal yang cepat tetapi tetap aman, minimal implementasikan:

```text
1. Permission middleware.
2. Generate kode jurusan.
3. Generate rombel.
4. Plotting rombel dengan validasi maksimal 2 rombel per ruang kelas.
5. Penempatan siswa manual + import siswa penempatan rombel.
6. Import wizard backend-only.
7. Export presensi XLSX/CSV.
8. Notifikasi: plotting_incomplete dan import_partial_failed.
9. Wali kelas basic CRUD.
10. Config module.exams.enabled = false diterapkan di menu/backend.
```

PDF export, email notification, dan frontend preview parser bisa masuk tahap berikutnya.
