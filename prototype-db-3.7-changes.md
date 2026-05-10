# DB 3.7 Changes - Upgrade Notifikasi Role/Group + AWS-like Preferences

Basis: `prototype-db-3.6.sql`  
Output: `prototype-db-3.7.sql`

## 1. Tujuan revisi

Versi 3.7 memperkuat model notifikasi yang sudah ada pada versi 3.5 dan 3.6. Fokus utamanya bukan membuat ulang sistem notifikasi, tetapi menambah lapisan konfigurasi yang lebih fleksibel.

Kebutuhan utama:

1. Admin dapat mengatur notifikasi untuk user dengan hak akses di bawahnya.
2. Guru, staff, dan siswa hanya dapat mengatur notifikasi opsional.
3. Notifikasi wajib, urgent, dan critical tetap dikendalikan sistem atau admin.
4. Pengaturan default tidak harus dibuat per user, terutama untuk siswa.
5. Konfigurasi mendukung model AWS-like: role, group, policy, permission, dan custom scope.

## 2. Keputusan desain

### 2.1 Tidak membangun ulang notifikasi

Tabel berikut tetap dipakai:

| Tabel | Status |
|---|---|
| `notification_rules` | dipertahankan dan diperkuat |
| `notifikasi` | dipertahankan dan ditambah metadata |
| `notifikasi_penerima` | dipertahankan |
| `user_notification_preferences` | dipertahankan dan diperkuat |
| `notifikasi_admin` | tetap sebagai legacy |

Desain lama sudah benar karena memisahkan event, penerima, dan preferensi user. Versi 3.7 hanya menambah kemampuan default preference berbasis role/group/policy.

### 2.2 Menambah tabel baru `role_notification_preferences`

Walaupun namanya `role_notification_preferences`, tabel ini tidak hanya mendukung role.

Tabel ini mendukung:

| Principal type | Fungsi |
|---|---|
| `role` | default berdasarkan role |
| `group` | default berdasarkan group, terutama untuk siswa |
| `policy` | default berdasarkan policy AWS-like |
| `permission` | default berdasarkan permission efektif |
| `custom` | default berbasis scope khusus |

Alasan tabel ini dibuat:

1. Menghindari isi data yang terlalu banyak di `user_notification_preferences`.
2. Siswa dapat memakai default group `students_default`.
3. Admin cukup mengatur default group/role tanpa mengubah preferensi satu per satu.
4. Tetap fleksibel untuk permission dan policy ala AWS.

## 3. Perubahan struktur tabel

### 3.1 Tabel `roles`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `role_level` | menentukan hierarki kewenangan role |

Aturan:

```text
angka lebih kecil = wewenang lebih tinggi
```

Default level yang di-seed:

| Role | Level |
|---|---:|
| `super_admin` | 10 |
| `admin_akademik` | 20 |
| `operator_lab` | 40 |
| `guru_pengawas` | 40 |
| `siswa` | 80 |
| `intern` | 90 |

Manfaat:

```text
admin hanya boleh mengatur notifikasi user dengan role_level lebih besar dari dirinya.
```

### 3.2 Tabel `groups`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `group_type` | kategori group, misalnya `student`, `notification`, `attendance` |
| `group_level` | level group untuk pengaturan default |
| `is_system` | penanda group bawaan sistem |

Group default yang ditambahkan:

| Group | Fungsi |
|---|---|
| `super_admins` | group super admin |
| `academic_admins` | group admin akademik |
| `lab_operators` | group operator lab |
| `teacher_supervisors` | group guru/pengawas presensi |
| `students_default` | default massal untuk siswa |
| `interns_read_only` | default intern |
| `notification_admins` | pengelola notifikasi |
| `import_operators` | operator import |

### 3.3 Tabel `notification_rules`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `importance_level` | level kepentingan: `optional`, `required`, `urgent`, `critical` |
| `target_group_slug` | target group default |
| `target_policy_slug` | target policy default |
| `default_popup_enabled` | default channel popup |
| `default_inbox_enabled` | default channel inbox |
| `default_email_enabled` | default email |
| `default_whatsapp_enabled` | default WhatsApp |
| `default_system_enabled` | default sistem/scheduler |
| `user_configurable` | apakah user boleh mengubah |
| `admin_configurable` | apakah admin boleh mengubah |
| `rule_ui_group` | group tampilan UI |
| `recommended_action` | rekomendasi aksi untuk user |

Aturan umum:

| Importance | User boleh mematikan? | Catatan |
|---|---:|---|
| `optional` | ya | non-urgent |
| `required` | tidak | wajib diketahui |
| `urgent` | tidak | perlu tindakan cepat |
| `critical` | tidak | dikunci sistem |

### 3.4 Tabel `notifikasi`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `importance_level` | snapshot importance saat notifikasi dibuat |
| `target_group_slug` | snapshot target group |
| `target_policy_slug` | snapshot target policy |
| `action_label` | label tombol aksi di UI |
| `action_url` | route/link FE menuju konteks masalah |

Tujuannya agar inbox notifikasi lebih modular dan bisa langsung mengarahkan user ke halaman penyelesaian.

### 3.5 Tabel `user_notification_preferences`

Kolom baru:

| Kolom | Fungsi |
|---|---|
| `configured_by_user_id` | siapa yang mengatur preferensi |
| `configuration_source` | sumber konfigurasi: self, admin, system, role_default, group_default |
| `is_admin_enforced` | jika 1, user tidak boleh override |
| `admin_note` | alasan atau catatan admin |

Ini mendukung aturan:

```text
admin boleh menetapkan preferensi user di bawahnya
guru/staff/siswa hanya boleh mengatur notifikasi opsional yang tidak dikunci
```

### 3.6 Tabel baru `role_notification_preferences`

Field penting:

| Field | Fungsi |
|---|---|
| `principal_type` | jenis sumber: role, group, policy, permission, custom |
| `principal_key` | kunci fleksibel: role_slug, group_slug, policy_slug, perm_slug, atau custom key |
| `role_id` | referensi role jika principal role |
| `group_id` | referensi group jika principal group |
| `policy_id` | referensi policy jika principal policy |
| `required_perm_slug` | referensi permission jika berbasis permission |
| `module_name` | modul notifikasi |
| `event_key` | event spesifik, boleh NULL untuk default module |
| `frequency` | inherit, instant, daily, weekly, off |
| `popup_enabled` | default popup, NULL berarti inherit |
| `inbox_enabled` | default inbox, NULL berarti inherit |
| `email_enabled` | default email, NULL berarti inherit |
| `whatsapp_enabled` | default WhatsApp, NULL berarti inherit |
| `system_enabled` | default system delivery |
| `is_muted` | default mute |
| `is_enforced` | tidak bisa dioverride user bawah |
| `priority` | prioritas resolver |
| `conditions_json` | kondisi AWS-like |

## 4. Notifikasi baru untuk alur scan HP

Rule baru:

| Event key | Importance | Tujuan |
|---|---|---|
| `attendance_scan_flagged_unresolved` | required | scan QR beda rombel belum di-resolve |
| `attendance_scan_session_interrupted` | urgent | guru keluar/terputus sebelum selesai scan |
| `attendance_rombel_unfinished` | required | masih ada siswa rombel belum presensi |
| `attendance_scanner_session_expired` | required | sesi scan kedaluwarsa |
| `notification_preference_admin_changed` | required | preferensi user diubah admin |
| `role_notification_preference_changed` | required | default role/group berubah |

## 5. Kenapa tidak memakai buffer tabel lain?

Tidak perlu tabel buffer tambahan untuk notifikasi.

Alasannya:

1. `notification_rules` sudah menjadi rule global.
2. `notifikasi` sudah menjadi event aktual.
3. `notifikasi_penerima` sudah menjadi daftar penerima final.
4. `user_notification_preferences` sudah menjadi override per user.
5. `role_notification_preferences` cukup untuk default role/group/policy.

Jika nanti performa inbox berat, baru pertimbangkan cache view/materialized table. Untuk versi 3.7 belum perlu.

## 6. Resolver prioritas yang disarankan

Backend sebaiknya menentukan preferensi efektif dengan urutan:

```text
1. notification_rules sebagai default utama
2. role_notification_preferences principal_type=policy
3. role_notification_preferences principal_type=permission
4. role_notification_preferences principal_type=group
5. role_notification_preferences principal_type=role
6. user_notification_preferences sebagai override akhir
```

Catatan:

- Jika `importance_level` adalah `required`, `urgent`, atau `critical`, user tidak boleh mematikan total.
- Jika `is_admin_enforced = 1`, preferensi user dikunci.
- Jika `role_notification_preferences.is_enforced = 1`, user di level bawah tidak boleh override.

## 7. View baru/diperbarui

| View | Fungsi |
|---|---|
| `v_notifikasi_inbox` | diperbarui agar membawa importance, target group, target policy, action label, action url |
| `v_role_notification_preferences_detail` | melihat default role/group/policy preference secara mudah |
| `v_notification_rules_admin` | tampilan admin untuk rule notifikasi |

## 8. Catatan implementasi backend

Backend perlu menambah validasi berikut:

1. Admin hanya boleh mengatur user dengan `role_level` lebih besar dari level admin.
2. User biasa hanya boleh mengubah preference dengan `importance_level = optional` dan `user_configurable = 1`.
3. Critical notification tidak boleh dimute penuh.
4. Required dan urgent minimal tetap masuk inbox.
5. Group default seperti `students_default` dipakai untuk siswa agar tidak perlu seed user preference massal.
6. `conditions_json` dibaca sebagai kondisi tambahan, misalnya scope `self/*` atau `own_or_assigned_rombel`.

## 9. Status revisi

Revisi 3.7 fokus pada notifikasi. Dokumentasi field otonom belum dilanjutkan karena bagian notifikasi memang membutuhkan perubahan struktur database lebih dulu.
