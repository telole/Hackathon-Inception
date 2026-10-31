# Kontrak API dan RPC PakaianKita

Versi 1.0 · 30 Oktober 2026 · Rancangan antarmuka backend

Kontrak ini menjelaskan operasi yang harus diimplementasikan pada Supabase. Nama RPC bukan endpoint yang sudah tersedia. Setiap command atomik berjalan pada satu transaksi PostgreSQL; Edge Function tidak merangkai update saldo sebagai beberapa request database.

## 1. Aturan umum

Flutter menggunakan Supabase SDK dengan JWT pengguna. Identitas actor diperoleh dari sesi server, bukan `user_id` yang dikirim client. UUID objek tetap diperiksa hubungannya. Kuantitas integer positif, waktu ISO 8601, dan daftar dipaginasi cursor.

Semua mutasi menerima `p_request_key uuid`; semua perubahan objek mutable juga menerima `p_expected_version integer`. Retry jaringan menggunakan key dan payload yang sama. Jika isi berubah, buat key baru setelah pengguna meninjau ulang. Ketika respons timeout, query objek atau retry key yang sama sebelum membuat tindakan lain.

Hasil sukses command:

```json
{
  "data": {
    "id": "uuid-objek",
    "status": "reserved",
    "version": 2
  },
  "request_key": "uuid-permintaan",
  "server_time": "2026-10-30T08:00:00Z"
}
```

Contoh UUID di dokumentasi bersifat placeholder, bukan nilai literal yang dikirim ke server. Error database menghasilkan exception PostgREST, bukan `{data:null}` yang dianggap sukses. Definisikan kode SQLSTATE aplikasi yang valid dan petakan ke AppFailure pada service Flutter.

| Kode aplikasi | Kondisi | Tindakan UI |
|---|---|---|
| AUTH_REQUIRED | Sesi tidak ada/berakhir | Masuk kembali, simpan draft |
| FORBIDDEN | Peran atau hubungan objek tidak sah | Tolak dan muat ulang izin |
| VALIDATION_ERROR | Field atau persamaan jumlah salah | Sorot field |
| VERSION_CONFLICT | Objek berubah sejak dibuka | Refresh dan tinjau ulang |
| STOCK_CONFLICT | Available lebih kecil dari qty | Tampilkan available terbaru |
| NEED_CLOSED | Tenggat lewat/ditutup/terpenuhi | Pilih kebutuhan lain |
| INVALID_TRANSITION | State tidak menerima aksi | Refresh detail |
| IDEMPOTENCY_CONFLICT | Key lama dipakai isi berbeda | Jangan retry otomatis |
| ALREADY_CONFIRMED | Receipt/handover sudah final | Buka hasil yang ada |
| AI_UNAVAILABLE | Provider gagal/tidak mendukung | Lanjut manual |

SQLSTATE usulan untuk migration: P1001…P1009 sesuai sembilan error domain pertama; AI_UNAVAILABLE dipetakan dari Edge HTTP error. Jangan bergantung pada pencarian substring pesan. Error detail untuk stok hanya memuat kuantitas objek yang actor boleh lihat.

## 2. Operasi baca

| Operasi | Parameter | Keluaran |
|---|---|---|
| get_my_context | Tidak ada actor ID | Profile, grant aktif, memberships, role contexts |
| list_needs | filter jenis/ukuran/wilayah/prioritas, cursor, limit | DTO need card + jumlah diterima/reserved/in_transit/sisa |
| get_need_detail | need_id | Header, lines, mitra/titik publik, eligibility |
| list_my_donations | status filter, cursor | Ringkasan donasi milik sesi |
| get_donation_detail | donation_id | Item, hasil kurasi, pengiriman yang relevan, timeline aman |
| find_matches | donation_item_id atau batch_id, limit | Kandidat, qty usulan, alasan, jarak; tanpa reserve |
| list_points | area atau koordinat dan radius terbatas | Titik verified aktif, jam, estimasi kapasitas |
| list_my_tasks | task status, cursor | Tugas relawan assigned |
| get_task_contact | task_id | Kontak/alamat privat hanya saat tugas aktif yang sah |
| list_inventory | point_id, variant_id, cursor | Batch dengan on_hand/reserved/available |
| get_shipment_detail | shipment_id | Lines, tugas, konfirmasi, kasus jika berizin |
| get_my_impact | periode | Potong diterima baik, lokasi mitra, data rujukan terpisah |

Operasi baca dapat berupa RPC atau select view security_invoker. Dokumen menggunakan nama operasi agar UI tidak terikat pada query tabel mentah. Jangan mengembalikan seluruh profile/alamat melalui join otomatis.

## 3. Command identitas dan kebutuhan

- `request_role(p_role, p_request_key)`: hanya volunteer; membuat pending, tidak memberi active/admin.
- `request_organization(p_payload, p_request_key)`: membuat organisasi pending dan membership pemohon pending; belum boleh publikasi.
- `approve_verification(p_target_type, p_target_id, p_decision, p_reason, p_request_key)`: admin saja, audit wajib.
- `save_need(p_need_id nullable, p_payload, p_expected_version nullable, p_request_key)`: manager mitra terverifikasi. Payload berisi destination_point_id, title, description, deadline_at, incident_id opsional dan lines `{variant_id, requested_qty}`. Counter tidak boleh ada dalam payload.
- `publish_need(p_need_id, p_expected_version, p_request_key)`: validasi field, masa aktif, target point, organisasi dan baris.
- `change_need_status(p_need_id, p_status, p_reason, p_expected_version, p_request_key)`: pause/close/reopen oleh pemilik; tutup tidak menghapus kiriman berjalan. Pembatalan reservasi dilakukan atomik bila dipilih petugas.

## 4. Command pengajuan dan kurasi

### create_donation_draft

Input `p_request_key`; output donation_id, tracking_code, version. Hanya donatur sesi. Item dapat kosong saat draft. Kode belum memberi klaim barang tersedia.

### save_donation_draft

Input ID/version/key dan payload item, handover_method, point, preferred_need_id, checklist, jadwal usulan, alamat pickup privat. Server memisahkan alamat ke private. Field status, donor_id, counter, dan approved tidak diterima dari client. Hanya draft/needs_revision.

### register_donation_photo

Input donation_id, item_id opsional, storage_path, expected_version, key. Verifikasi objek Storage, pemilik path, ukuran/MIME, serta batas foto. Upload object terjadi sebelum command; jika gagal registrasi, object dapat dibersihkan kemudian. Edit/hapus foto hanya pada tahap yang diizinkan.

### submit_donation

Input ID/version/key. Wajib item lengkap, foto terdaftar, seluruh checklist true, dan metode/titik valid. Output submitted + event; tombol UI tidak mengubah status lokal menjadi sukses sebelum respons server.

### review_donation

Input donation_id, decision (`approve`, `request_revision`), note, version, key. Aktor admin/petugas kurasi yang ditugaskan. Approve mengizinkan penjadwalan, belum membuat stok. Jadwal dikonfirmasi melalui `schedule_handover` oleh petugas dengan donor mengetahui waktu yang disetujui.

### record_inspection

```json
{
  "p_item_id": "uuid-item",
  "p_point_id": "uuid-titik",
  "p_checked_qty": 10,
  "p_passed_qty": 8,
  "p_rejected_qty": 2,
  "p_rejection_reason": "Robek pada bagian utama",
  "p_expected_version": 3,
  "p_request_key": "uuid-request"
}
```

Hanya volunteer aktif dengan tugas curation item/titik tersebut atau admin. Barang telah berada dalam penguasaan titik/petugas melalui handover sah. Return inspection_id, batch_id bila passed>0, referral_id bila rejected>0, dan sisa belum diperiksa. Server membuat batch, ledger, event, serta rujukan atomik.

## 5. Command inventaris dan penyaluran

### reserve_allocation

Input batch_id, need_line_id, qty, expected versions batch/need line, key. Pengelola sumber/admin. Output allocation_id, qty dan saldo terbaru. Query matching bukan otorisasi untuk reserve; fungsi memeriksa ulang seluruh syarat.

### create_shipment

Input allocation_ids[], key. Pengelola sumber. Pastikan allocation belum memiliki shipment, sumber/tujuan sama, dan semuanya reserved. Return shipment_id dan line IDs. Tidak mengurangi on_hand sampai dispatch.

### assign_task dan respond_task

assign_task menerima kind, object ID, volunteer_id, jadwal, key; dilakukan operator titik/admin, volunteer wajib aktif. respond_task menerima task_id, accept/decline, reason, version, key; hanya assigned volunteer. Tolak membuka antrean penugasan ulang, tidak menghapus riwayat.

### offer_handover dan confirm_handover

offer mencatat task, qty, note/evidence dan key; pengirim sah saja. confirm menerima handover_id, decision, note, key; penerima berbeda yang sah. Pickup membutuhkan donatur dan relawan, dropoff donatur dan operator titik. Pengiriman membutuhkan petugas sumber/relawan lalu penerima tujuan. Kuantitas harus sesuai objek terkait; perbedaan membuka kasus/tindak lanjut.

### dispatch_shipment

Input shipment_id, version, key. Relawan delivery assigned yang accepted/in_progress atau admin beralasan. Handover sumber telah dikonfirmasi. Ubah semua saldo dalam transaksi seperti database.md. Return in_transit dan event. Retry tidak membuat pengurangan kedua.

### confirm_receipt

Input shipment_id, version, key dan lines `{shipment_line_id, good_qty, rejected_qty, missing_qty, reason}`. Hanya anggota aktif organisasi tujuan; bukan relawan pengantar yang mengonfirmasi atas nama penerima. Daftar harus lengkap dan jumlah sesuai setiap line. Return receipt_id, shipment_status (`received` atau `disputed`), dispute_ids.

### resolve_dispute

Input dispute_id, accepted_late_qty, released_need_qty, reason, evidence opsional, key. Admin dengan bukti penerima untuk accepted_late. Tidak boleh melebihi held yang tersisa. Return saldo held dan status kasus. Jika barang retur, logistik retur dan inspeksi baru ditangani terpisah; stok tidak muncul dari command ini.

### cancel_allocation dan reallocate_reserved_stock

Cancel: allocation_id, reason, version, key; operator sumber/admin; reserved dan belum dispatch. Reallocate: old_allocation_id, new_need_line_id, reason, key; admin, kuantitas penuh MVP, kebutuhan baru memenuhi syarat. Counter asal/batch/tujuan dan audit berubah atomik.

## 6. Command bencana dan daur ulang

- `request_incident(payload, key)`: mitra terverifikasi, isi wilayah/periode/alasan.
- `activate_incident(incident_id, version, reason, key)`: admin, periode valid; hanya memberi prioritas, tidak langsung memindahkan alokasi.
- `close_incident(incident_id, version, reason, key)`: admin; kiriman berjalan tetap ditangani.
- `update_recycling_referral(referral_id, partner_id, new_status, evidence, version, key)`: petugas terkait/admin. processing_confirmed membutuhkan konfirmasi mitra yang dapat ditelusuri.

## 7. Edge Function classify-donation

Route rencana `/functions/v1/classify-donation`, POST, JWT pengguna wajib. Body `{donation_id, photo_id, request_key}`. Pemeriksaan: actor owner/assigned, photo terikat donasi, object berada dalam bucket privat yang benar, rate limit, dan feature flag aktif.

Respons 200 jika hasil tersimpan, 202 jika pekerjaan sudah pending, 401 sesi tidak sah, 403 tidak berizin, 422 foto/model tidak didukung, 429 limit, 503 provider gagal. AI_UNAVAILABLE di UI tidak mengubah pengajuan menjadi gagal. Jangan mengirim token/kunci provider ke Flutter.

Output suggestion terkontrol: `category_candidate`, `visible_condition_notes`, `uncertain_fields`, dan `human_review_required: true`. Model tidak mengisi ukuran atau kebersihan sebagai fakta jika tidak dapat dibuktikan dari foto. Flag source membedakan provider nyata dari fixture demo.

## 8. Subscription

Client subscribe donation_events pada donation yang berizin dan notifications pada user sesi. Saat event diterima, repository invalidate query detail serta impact bila relevan. Gunakan ID event sebagai deduplication key. Setelah reconnect lakukan fetch ulang; subscription bukan pengganti read terotorisasi.

## 9. Kontrak Dart konseptual

```dart
abstract interface class InventoryRepository {
  Future<AllocationResult> reserve({
    required String batchId,
    required String needLineId,
    required int quantity,
    required int batchVersion,
    required int needLineVersion,
    required String requestKey,
  });
}
```

Ini contoh antarmuka desain, bukan source aplikasi lengkap. Service memanggil `supabase.rpc`, memetakan SQLSTATE ke AppFailure, dan mengembalikan typed result. Controller tidak menghitung saldo final sendiri.
