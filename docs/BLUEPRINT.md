# NARA — Product Blueprint (Final)

> *"Pendamping pintarmu, setiap hari." / "Your smart companion, every day."*

## 1. Keputusan Final (dari percakapan ChatGPT)

| Keputusan | Nilai |
|---|---|
| Nama produk | **NARA** |
| Platform | **Android** (Flutter — siap diperluas ke iOS) |
| Strategi AI | **Hybrid** — tier 1 on-device (instan, offline), tier 2 cloud (Gemini, opsional) |
| Positioning | **Super** — asisten pribadi + produktivitas + kebiasaan dalam satu app |
| Bahasa | **Bilingual** — Indonesia & Inggris (bisa di-switch kapan saja, default ikut sistem) |
| Backend | **Firebase** — Auth (Google Sign-In), Firestore (realtime sync), dengan **local mode** fallback untuk demo/offline penuh |

## 2. Masalah & Pasar

Orang butuh satu tempat untuk **menangkap pikiran, mengelola tugas, dan membangun kebiasaan** — bukan 5 aplikasi terpisah. Aplikasi to-do biasanya kaku; asisten AI biasanya hanya chatbot tanpa aksi. **NARA menggabungkan keduanya**: asisten yang bisa *bertindak* (membuat tugas/catatan, mengisi kebiasaan) + perangkat produktivitas yang elegan dan bekerja offline.

Target pengguna awal: pelajar, pekerja muda, dan kreator di Indonesia yang ingin pendamping harian yang ringan, indah, dan paham bahasa Indonesia.

## 3. Value Proposition

1. **Asisten yang bertindak** — "buat tugas belanja besok jam 8" → tugas nyata muncul, bukan cuma jawaban teks.
2. **Hybrid AI** — respons instan di perangkat tanpa internet; makin terbuka & pintar saat user menghubungkan AI Cloud (key Gemini maupun provider OpenAI-compatible, base URL/model custom).
3. **Satu app untuk hari** — Tugas, Catatan, Kebiasaan, dan Chat AI dalam satu navigasi bawah yang ringkas.
4. **Offline-first** — data selalu tersedia; sinkron cloud saat online (Firestore).
5. **Elegan & personal** — tema gelap/terang Material 3, tipografi Poppins, sapaan personal, streak yang memotivasi.

## 4. Modul (MVP Produksi)

| Modul | Fungsi inti | Status |
|---|---|---|
| Onboarding | 3 slide value prop + pilih mulai | ✅ |
| Auth | Google Sign-In (Firebase) — login pertama otomatis daftar, profil lokal untuk mode demo | ✅ |
| Beranda | Sapaan, saran AI, 4 statistik, aksi cepat, tugas hari ini, check-in kebiasaan | ✅ |
| NARA AI | Chat hybrid, riwayat persist, aksi otomatis (buat tugas/catatan, check-in), badge sumber (on-device/cloud) | ✅ |
| Tugas | CRUD, prioritas, kategori, tenggat (+jam), filter (Semua/Hari ini/Mendatang/Selesai), undo hapus | ✅ |
| Catatan | CRUD, pencarian, pin, 6 warna, autosave | ✅ |
| Kebiasaan | CRUD, check-in harian, streak, progress mingguan, target/minggu | ✅ |
| Profil/Setting | Edit profil, tema, bahasa, pengingat harian (notifikasi), AI key, about, hapus data | ✅ |
| Pengingat | Notifikasi harian terjadwal (flutter_local_notifications) | ✅ |

## 5. User Journey Utama

1. **First run** → Splash → Onboarding (3 slide) → Buat profil/akun → Beranda.
2. **Capture cepat** → Chat AI: *"buat tugas laporan besok jam 9"* → konfirmasi + tugas muncul di Beranda & tab Tugas.
3. **Rutinitas pagi** → Notifikasi pengingat → buka app → check-in kebiasaan (streak naik) → lihat tugas hari ini.
4. **Refleksi** → catat ide di Catatan (autosave), cari kembali lewat pencarian.
5. **Kembali** → semua data tersinkron (Firebase) atau tersimpan aman di perangkat (local mode).

## 6. Monetisasi (Roadmap, bukan MVP)

- Free: semua fitur inti + AI on-device tanpa batas.
- NARA+ (opsional): AI Cloud tanpa perlu key sendiri (proxy backend), statistik lanjutan, tema eksklusif.
- Model biaya: biaya LLM ditanggung via backend proxy + langganan bulanan murah.

## 7. Roadmap Pasca-MVP

1. Google Sign-In + sinkronisasi lintas perangkat penuh.
2. Widget home screen (tugas hari ini + check-in cepat).
3. Pengingat per-tugas (bukan hanya harian).
4. Ekspor data (JSON/CSV) & backup.
5. AI Cloud via Cloud Function proxy (key tak pernah di klien).
6. iOS release + lokal ketiga (mis. Jawa/Sunda).

## 8. Metrik Kesuksesan (North Star)

- **D7 retention** ≥ 25% (pendamping harian).
- **Check-in kebiasaan / user / minggu** ≥ 4.
- **Tugas dibuat via AI** ≥ 30% dari total tugas (bukti value hybrid AI).
- Crash-free rate ≥ 99.5%.
