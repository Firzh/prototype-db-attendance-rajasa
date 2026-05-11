# Rajasa DB 3.8 MVP Modular

Paket ini adalah pecahan modular dari DB 3.8 dengan future development berikut dihapus:

- `ai_recognition_jobs`;
- modul ujian: `sesi_ujian`, `peserta_ujian`;
- modul nilai: `mata_pelajaran`, `nilai_akademik`;
- channel notifikasi WhatsApp/email.

## Import cepat

Salin folder ini ke repo:

```text
database/3.8-mvp-modular/
```

Reset DB lokal:

```bash
docker compose exec db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"'
```

Import modul berurutan:

```bash
for f in database/3.8-mvp-modular/modules/[0-9][0-9][0-9]_*.sql; do
  echo "==> $f"
  docker compose exec -T db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < "$f"
done
```

Cek hasil:

```bash
docker compose exec db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE" -e "SELECT * FROM schema_versions ORDER BY applied_at DESC; SHOW TABLES;"'
```

## Rombel display

Keputusan sistem:

```text
Input mitra : 10 AKL
Internal    : tingkatan=X, tingkat_angka=10, jurusan=AKL, nomor_rombel=1
Tampilan    : 10 AKL
Bukan       : 10 AKL 1
```
