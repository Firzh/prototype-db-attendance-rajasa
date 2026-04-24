# Tambahan Database pada Prototype DB 3.3

## 1. Ringkasan perubahan

Prototype DB 3.3 merevisi prototype DB 3.2 dengan fokus pada:

```text
Manage Users
Log Users
user_activities
custom QR akses akun sementara
cold archive bulanan
buffer tampilan
view untuk tabel utama dan advanced detail
```

## 2. Tabel yang diganti

### Dari

```text
admin_activities
```

### Menjadi

```text
user_activities
```

Alasan:

`admin_activities` terlalu sempit karena log tidak hanya mencatat admin. Sistem juga perlu mencatat operator, guru_staff, siswa, pengawas, intern, magang, dan akun system.

## 3. Tabel baru pada DB 3.3

| No | Tabel | Fungsi |
|---:|---|---|
| 1 | `user_access_tokens` | Menyimpan custom QR/token akses akun sementara untuk pengawas, intern, atau magang. Berbeda dari `qr_tokens` siswa. |
| 2 | `user_activity_cold_archives` | Menyimpan metadata export dan kompresi cold archive bulanan untuk `user_activities`. |
| 3 | `user_activities` | Audit log utama seluruh aktivitas user. Mengganti `admin_activities`. |
| 4 | `user_manage_buffer` | Cache tampilan Manage Users. Dipakai bila query join mulai berat. |
| 5 | `user_activity_display_buffer` | Cache tampilan Log Users. Dipakai bila data log besar. |

## 4. View baru pada DB 3.3

| No | View | Fungsi |
|---:|---|---|
| 1 | `v_manage_users` | View gabungan untuk tabel Manage Users. |
| 2 | `v_user_activities_display` | View ringkas untuk tabel utama Log Users. |
| 3 | `v_user_activities_advanced` | View detail untuk tombol See Advanced. |

## 5. Struktur inti user_activities

Field utama:

```text
log_id
user_id
username_snapshot
nama_lengkap_snapshot
nisn_snapshot
role_snapshot
role_slug_snapshot
user_type_snapshot
action_type
module_name
target_table
target_id
status
activity_description
ruangan_id
kode_ruangan_snapshot
ip_address
user_agent
archive_status
archived_at
cold_archive_id
arsip_batch_id
created_at
```

## 6. Kenapa user_activities memakai snapshot

Snapshot dipakai agar log tetap stabil secara historis.

Data user bisa berubah. Username, nama, role, jurusan, atau status bisa berubah setelah aktivitas terjadi. Log lama tetap harus mencerminkan kondisi saat aktivitas terjadi.

Snapshot yang dipakai:

```text
username_snapshot
nama_lengkap_snapshot
nisn_snapshot
role_snapshot
role_slug_snapshot
user_type_snapshot
kode_ruangan_snapshot
```

## 7. Struktur inti user_access_tokens

Field utama:

```text
token_id
user_id
token_reference
token_payload_hash
token_type
valid_from
valid_until
max_use_count
used_count
status
issued_by
revoked_by
revoked_at
revoked_reason
created_at
updated_at
```

Fungsi:

```text
Mendukung custom QR atau token akses untuk akun sementara seperti pengawas, intern, dan magang.
```

Catatan penting:

`user_access_tokens` tidak menggantikan `qr_tokens`. Keduanya berbeda fungsi.

| Tabel | Fungsi |
|---|---|
| `qr_tokens` | QR siswa untuk presensi/ruangan. |
| `user_access_tokens` | QR/token akses akun user sementara. |

## 8. Struktur inti user_activity_cold_archives

Field utama:

```text
cold_archive_id
periode_tahun
periode_bulan
periode_mulai
periode_selesai
source_table
record_count
exported_file_name
compressed_file_name
compressed_format
storage_disk
storage_path
checksum_sha256
file_size_bytes
arsip_batch_id
media_id
status
executed_by
started_at
finished_at
error_message
created_at
updated_at
```

Fungsi:

```text
Mencatat metadata export dan kompresi log bulanan agar archive bisa diaudit dan dipulihkan.
```

## 9. Buffer tampilan

### user_manage_buffer

Dipakai untuk mempercepat halaman Manage Users.

Field ringkas:

```text
user_id
username
nama_lengkap
nisn
role_summary
primary_role_slug
user_type
jurusan_id
kode_jurusan
nama_jurusan
status
valid_until
valid_until_class
last_login
online_status
last_activity
created_at_source
updated_at_source
synced_at
```

### user_activity_display_buffer

Dipakai untuk mempercepat halaman Log Users.

Field ringkas:

```text
log_id
user_label
username_snapshot
nisn_snapshot
role_snapshot
role_slug_snapshot
user_type_snapshot
action_type
module_name
target_table
target_id
status
keterangan_ringkas
ruangan_id
ruangan_label
ip_address
browser_device
activity_created_at
archive_status
synced_at
```

## 10. Index penting yang ditambahkan

### user_activities

```text
user_id + created_at
username_snapshot + created_at
nisn_snapshot + created_at
role_slug_snapshot + user_type_snapshot + created_at
action_type + module_name + created_at
status + created_at
target_table + target_id
ruangan_id + created_at
archive_status + created_at
cold_archive_id
arsip_batch_id
```

### user_manage_buffer

```text
username + nisn + nama_lengkap
primary_role_slug + user_type
jurusan_id + status
valid_until_class + valid_until
last_login
online_status + last_activity
```

### user_activity_display_buffer

```text
username_snapshot + nisn_snapshot + user_label
role_slug_snapshot + user_type_snapshot
action_type + module_name + activity_created_at
status + activity_created_at
target_table + target_id
ruangan_id + activity_created_at
ip_address + activity_created_at
archive_status + activity_created_at
```

## 11. RFID check

Pada prototype DB 3.3 tidak ada field utama RFID seperti:

```text
rfid_uid
rfid_id
card_uid
uid_rfid
```

Sisa kata RFID hanya muncul pada catatan desain untuk menjelaskan bahwa sistem tidak memakai RFID sebagai sumber utama. Sistem berjalan dengan QR dan audit user activity.

## 12. Migrasi dari admin_activities

File SQL menyertakan contoh backfill opsional:

```text
admin_activities versi 3.2 ke user_activities versi 3.3
```

Backfill itu berada dalam komentar. Jalankan hanya jika database lama sudah punya data `admin_activities`.

## 13. Output file SQL

Output revisi database:

```text
prototype-db-3.3.sql
```

Isi utama:

```text
schema DB versi 3.3
user_access_tokens
user_activities
user_activity_cold_archives
user_manage_buffer
user_activity_display_buffer
view manage users
view user activities display
view user activities advanced
contoh backfill opsional
```

    