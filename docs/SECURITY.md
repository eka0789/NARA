# NARA — Security Notes

## 1. Autentikasi & Otorisasi

- **Firebase Auth** via **Google Sign-In** — satu-satunya metode kredensial (login pertama = otomatis daftar). Tidak ada alur email/password lagi, sehingga tidak ada attack surface "enumeration" kredensial; kegagalan dipetakan ke pesan aman (`AuthException` → l10n) tanpa membocorkan detail internal. Pembatalan alur Google dibungkus senyap (bukan error). Prasyarat konfigurasi: SHA-1 + klien OAuth di Firebase Console.
- **Otorisasi server-side**: Firestore Security Rules membatasi seluruh pohon data ke `request.auth.uid == uid` (deny by default). Klien tidak bisa membaca/menulis data user lain meski API dipanggil langsung.
- Tidak ada endpoint kustom tanpa otorisasi — semua akses data melewati rules.

## 2. Data & Privasi

- Data user hanya: nama, email, emoji avatar, dan konten buatan user (tugas/catatan/habit/chat). Tidak ada data lokasi, kontak, atau perangkat yang dikumpulkan.
- **Hapus data**: fitur "Hapus semua data" menghapus seluruh dokumen Firestore + akun Auth (menangani `requires-recent-login` dengan jujur — data hilang, akun bisa dihapus ulang setelah re-auth).
- Chat dengan AI Cloud: hanya teks pesan + konteks minimal (nama, daftar judul tugas terbuka) yang dikirim ke API Gemini. Tidak ada token/kredensial di payload.
- Log/catatan aplikasi tidak berisi data sensitif.

## 3. API Key Gemini

- Dua jalur: `--dart-define=NARA_GEMINI_API_KEY` (build-time) atau input user di Profil (disimpan **hanya di perangkat**, via SharedPreferences, tidak pernah ke Firestore).
- **Custom endpoint (Profil → AI Cloud: base URL/model/format Gemini↔OpenAI)**: key dikirim ke host yang diisi user — pilih host tepercaya dan utamakan `https://`. Validasi `http(s)` + uji simpan memblokir URL salah sebelum tersimpan.
- ⚠️ **Catatan produksi**: key yang di-bundle di klien tetap dapat diekstrak dari APK. Untuk produksi skala besar, proxy panggilan melalui **Cloud Function / backend** dengan key di server + rate limit per user, lalu hilangkan key dari klien (lihat ROADMAP). Key milik user sendiri (BYO key) berada sepenuhnya di tanggung jawab dan perangkat user.

## 4. Keamanan Klien Android

- `minSdk 23`; izin minimum: `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, `WAKE_LOCK` (hanya untuk pengingat harian).
- Tidak ada `android:exported` terbuka selain MainActivity; receiver notifikasi `exported=false`.
- Tidak ada WebView, tidak ada `allowBackup` kustom, tidak ada debug logging yang dibawa ke release.
- Dependensi dari pub.dev resmi; versi di-pin pada major di `pubspec.yaml` (audit berkala: `flutter pub outdated`).

## 5. Input & Abuse

- Semua input tugas/catatan/habit dibatasi panjang natural dan dirender sebagai teks Flutter (bukan HTML) → XSS tidak relevan; injeksi Firestore tidak mungkin karena API bertipe (tanpa string query).
- Chat AI: teks user tidak dieksekusi; keluaran cloud dirender sebagai teks biasa (SelectableText).
- Rule engine on-device murni deterministik (tanpa eval/kode dinamis).
- Rate limit cloud AI berada di sisi Google (429 → pesan kuota); untuk backend proxy produksi tambahkan limit per-user.

## 6. Hal yang SENGAJA Tidak Ada di MVP (jujur)

- Enkripsi-at-rest tambahan di atas Firestore default & SharedPreferences (datanya non-sensitif; jika nanti ada data sensitif → pakai `flutter_secure_storage`/EncryptedSharedPreferences).
- Penandatanganan release keystore & App Play Signing (tanggung jawab pemilik akun Play).
- Proxy Cloud Function untuk AI (roadmap item #5).
