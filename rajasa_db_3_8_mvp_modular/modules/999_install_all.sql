-- =========================================================
-- INSTALL ALL RAJASA DB 3.8 MVP MODULAR
-- Run from repository root with:
-- docker compose exec -T db sh -lc 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD"' < database/3.8-mvp-modular/modules/999_install_all.sql
-- If SOURCE path fails, run each file in numeric order.
-- =========================================================
SOURCE database/3.8-mvp-modular/modules/000_database_and_version.sql;
SOURCE database/3.8-mvp-modular/modules/001_access_base.sql;
SOURCE database/3.8-mvp-modular/modules/002_academic_identity.sql;
SOURCE database/3.8-mvp-modular/modules/003_users_access_runtime.sql;
SOURCE database/3.8-mvp-modular/modules/004_facility_schedule_scanner.sql;
SOURCE database/3.8-mvp-modular/modules/005_files_archive_audit.sql;
SOURCE database/3.8-mvp-modular/modules/006_attendance_qr_online.sql;
SOURCE database/3.8-mvp-modular/modules/007_support_config_buffers.sql;
SOURCE database/3.8-mvp-modular/modules/008_import_wizard.sql;
SOURCE database/3.8-mvp-modular/modules/009_notification_lite.sql;
SOURCE database/3.8-mvp-modular/modules/010_seed_minimal_mvp.sql;
SOURCE database/3.8-mvp-modular/modules/011_views_mvp.sql;
