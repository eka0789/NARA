# NARA — UI/UX Design Spec (seluruh layar)

## 1. Design Language

| Token | Nilai | Pemakaian |
|---|---|---|
| Primary | `#5B5BD6` (indigo) | CTA, nav aktif, aksen |
| Gradient brand | `#5B5BD6 → #8B5CF6` | CTA utama, logo, bubble user |
| Success/Teal | `#14B8A6` | badge cloud sync, prioritas rendah |
| Amber | `#F59E0B` | streak, prioritas sedang, mode lokal |
| Coral | `#EF476F` | prioritas tinggi, overdue |
| Background light | `#F6F6FB` | scaffold |
| Background dark | `#0E0F16`, surface `#171A23` | dark theme |
| Radius | 16 (button/input) · 20 (card) · 28 (sheet/nav) | konsisten |
| Tipografi | **Poppins** 400/500/600/700, judul SemiBold/Bold | seluruh app |
| Shadow | lembut berlapis (blur 12–24, y 4–10, alpha 5–28%) | card, nav, CTA |

Prinsip: **soft-depth** (kartu putih + hairline border + bayangan tipis, bukan flat), **motion halus** (entrance fade+slide 420ms, cascade 40–80ms per item, hormati *reduce motion*), **feedback selalu ada** (loading spinner di CTA, snackbar aksi, state kosong/ilustratif di setiap list).

## 2. Navigasi

- **Bottom nav floating pill** (5 tab): Beranda · NARA AI · Tugas · Kebiasaan · Profil — pill dengan highlight aktif + glow ikon, state tersimpan per-tab (IndexedStack).
- Sub-halaman di-push penuh: Catatan (`/notes`, `/notes/:id`).
- Form tugas/kebiasaan/edit-profil: **bottom sheet** (keyboard-aware).
- Router: `go_router` + redirect guard (onboarding → auth → shell).

## 3. Layar demi layar

### 3.1 Splash
Gradient indigo→violet penuh, kartu logo "N" putih (radius 28, bayangan dalam), wordmark NARA (letter-spacing 6), tagline. Fade-in 700ms, auto-route setelah 1,5s.

### 3.2 Onboarding (3 slide, swipe)
- Ilustrasi: blob gradient + ikon besar + 3 badge emoji melayang (bayangan lembut).
- Slide 1 "Kenalan dengan NARA" (👋), 2 "Satu aplikasi untuk harimu" (🗂️), 3 "Asisten yang benar-benar bertindak" (🤖).
- Judul headline-medium 26 bold; teks center; dot indicator animasi lebar; tombol gradient "Lanjut → Mulai sekarang"; Skip di kanan atas.

### 3.3 Login / Register
Header logo + judul besar; **mode cloud**: satu CTA "Lanjutkan dengan Google" (permukaan putih, radius-16, border hairline, logo G 4-warna, spinner loading saat proses, pembatalan = senyap); **mode lokal**: banner informasi khusus mode lokal (ikon petir, latar indigo 6%) + CTA gradient 52px "Mulai dengan profil" → layar daftar. Register mode lokal: hanya nama + CTA; register mode cloud: CTA Google + footer "Sudah punya akun? Masuk".

### 3.4 Beranda
- Header: sapaan waktu (pagi/siang/malam/melek), nama user besar (headline 26), tanggal; avatar emoji lingkaran gradient → /profil.
- **Kartu saran AI**: gradient tint, ikon ⚡ gradient, label "NARA menyarankan", teks saran kontekstual (dari engine on-device) — tap → chat.
- **4 StatTile**: Tugas hari ini · Kebiasaan selesai · Streak terbaik · Catatan (ikon berwarna, angka besar).
- **3 aksi cepat**: Tugas baru (sheet) · Catatan baru · Isi kebiasaan.
- **Tugas hari ini**: maks 3 kartu (checkbox outline warna prioritas, jam) + empty state 🌤️.
- Semua blok punya entrance cascade.

### 3.5 NARA AI (chat)
- AppBar: logo ⚡ gradient + judul + subjudul badge (AI Cloud / Asisten pribadimu) + tombol bersihkan (dialog konfirmasi).
- Banner kuning bila AI Cloud belum terhubung → tombol "Tambah key" → /profil.
- Bubble user: gradient brand, kanan, ekor bawah-kanan; bubble AI: surface + border, kiri, badge sumber kecil (⚡ AI Cloud / 📱 Di perangkat); teks selectable.
- Typing indicator: 3 titik animasi sinus + "NARA sedang berpikir…".
- Empty state: logo besar glow + 4 chip saran pertanyaan (tap langsung kirim).
- Input bar: field multi-baris + tombol lingkaran gradient yang menyala saat ada teks; disable saat thinking.
- Banner error merah bila cloud gagal (key invalid/kuota) — percakapan tetap lanjut via engine lokal.

### 3.6 Tugas
- AppBar "Tugas" + FAB gradient "Tugas baru".
- Baris FilterChip dengan hitungan: Semua · Hari ini · Mendatang · Selesai.
- Tile: strip warna prioritas kiri, judul (strikethrough saat selesai), chip kategori + label tenggat (merah + ⚠ saat overdue), checkbox custom.
- Urutan: overdue → prioritas → tanggal; swipe kiri = hapus + **Undo** di snackbar; tap = edit sheet.
- Form sheet: judul (autofocus), catatan, SegmentedButton prioritas, ChoiceChip kategori (Umum/Kerja/Belajar/Kesehatan/Pribadi), chip tenggat (Tanpa tanggal/Hari ini/Besok/DatePicker), CTA simpan, hapus saat edit.

### 3.7 Catatan
- Search bar; grid 2 kolom; kartu warna pastel (6) / deep (dark), pin di kanan judul, pratinjau isi, tanggal + hapus; urut pin → terbaru; hapus + Undo.
- Editor: palet warna horizontal + chip pin; judul borderless besar; isi borderless expanded; **autosave** saat keluar; tombol ✓ menyimpan + kembali.

### 3.8 Kebiasaan
- Kartu per kebiasaan: avatar emoji (warna dari 6 palet), nama, 🔥 streak (label lokal), target ×/minggu; tombol check-in yang "menyala" saat selesai hari ini; baris 7 titik mingguan (Sen–Min) — titik terisi warna, lingkaran outline = hari ini.
- Form sheet: nama, pilih emoji (12), warna otomatis, slider target 1–7, simpan/hapus.

### 3.9 Profil
- Kartu header: avatar emoji, nama, email, **badge mode** (🟠 Mode lokal / 🟢 Sinkron cloud), tombol edit → sheet (nama + pilih 12 emoji).
- 3 statistik ringkas.
- Pengaturan (tile ikon warna): Tampilan (Sistem/Terang/Gelap) · Bahasa (Sistem/Indonesia/Inggris) · Pengingat harian (switch + pemilih jam, konfirmasi snackbar, pesan bila izin ditolak) · AI Cloud key (sheet: key + pemilih format Gemini/OpenAI + Base URL + Model, validasi http(s) & uji simpan, reset field kosong ke default, hapus key) · Tentang NARA (versi) · Keluar · **Hapus semua data** (merah, dialog konfirmasi destruktif).

## 4. State & Aksesibilitas

- Setiap list punya **loading** (spinner center), **empty** (ilustrasi ikon + judul + CTA), dan **error** (snackbar/banner) state.
- Kontras teks ≥ 4.5:1 di kedua tema; target sentuh ≥ 44px; label pada ikon aksi; `reduce-motion` menghentikan animasi entrance.
- Semua string terlokalisasi (ARB id/en), format tanggal adaptif bahasa.
