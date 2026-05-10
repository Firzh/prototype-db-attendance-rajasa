Isi revisi utama:

Tetap mempertahankan perangkat_esp32 dan ruangan_perangkat sebagai legacy.
Menambah scanner_devices untuk HP, tablet, desktop browser, dan device scanner umum.
Menambah scanner_sessions untuk sesi scan guru/admin/staff.
Menambah field web scanner di log_scan_qr.
Menambah field flagged di log_scan_qr.
Tidak membuat tabel buffer flagged.
Memperkuat presensi dengan anti double scan.
Menambah presensi_source, scanner_session_id, dan input_by_user_id.
Menambah dukungan audit event scanner melalui user_activities.metadata_json.
Menambah permission web scanner.
Menambah konfigurasi default web scanner.
Menambah view:
v_log_scan_ringkas
v_log_scan_qr_detail
v_scanner_sessions_ringkas
v_scan_qr_flagged_unresolved