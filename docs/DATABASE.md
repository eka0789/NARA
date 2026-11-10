# NARA — Firestore Schema & Data Model

## 1. Struktur Koleksi

Semua data user berada di bawah `users/{uid}` — isolasi per-user di level path + security rules.

```
users/{uid}
├── name, email, avatarEmoji, createdAt        ← dokumen profil
├── prefs: { language, themeMode, dailyReminder,
│            reminderHour, reminderMinute }     ← preferensi (mirror dari local shadow)
│
├── tasks/{taskId}
│     title, note, done, priority (0|1|2),
│     category ('general'|'work'|'study'|'health'|'personal'),
│     dueDate (ms epoch | null), createdAt, updatedAt
│
├── notes/{noteId}
│     title, body, colorIndex (0..5), pinned,
│     createdAt, updatedAt
│
├── habits/{habitId}
│     name, emoji, colorIndex (0..5), targetPerWeek (1..7),
│     archived, createdAt
│   └── habits/{habitId}/logs/{yyyy-MM-dd}
│         done: true, at (serverTimestamp)
│
└── chats/main
      updatedAt
    └── chats/main/messages/{msgId}
          role ('user'|'assistant'), text,
          source ('local'|'cloud'), createdAt
```

### Keputusan desain penting

1. **Log kebiasaan = dokumen per hari** (`logs/2026-11-10`). Murah, idempoten, aman lintas zona waktu (kunci hari lokal), dan membuat perhitungan streak/progress mingguan hanya perlu set tanggal.
2. **Tipe tanggal = milidetik epoch** di map aplikasi; repositori Firebase menerima `Timestamp` Firestore maupun int (lihat `Task.fromMap`). Ini membuat model identik untuk penyimpanan lokal (JSON) dan Firestore.
3. **Satu percakapan chat** (`chats/main`) untuk MVP; schema siap dikembangkan ke banyak chat tanpa migrasi (tambah `chatId`).
4. **Chat dibatasi 200 pesan** terakhir saat dibaca (`limit(200)`) — riwayat lama tetap tersimpan tapi tidak membebani baca.

## 2. Local Mode (fallback demo/offline)

Tanpa Firebase, repositori lokal (`Local*Repository`) menyimpan data yang sama via `SharedPreferences` sebagai JSON:

| Key | Isi |
|---|---|
| `nara.profile` | UserProfile (uid `local`) |
| `nara.tasks` / `nara.notes` / `nara.habits` | array map model |
| `nara.habit_logs` | `{habitId: [dateKey...]}` |
| `nara.chat` | array ChatMessage (max 200) |
| `nara.prefs` | UserPrefs shadow (selalu lokal, cepat saat boot) |
| `nara.onboarding_seen`, `nara.ai_key` | flag & key perangkat |

`LocalStore.watch()` memancarkan perubahan seperti snapshot Firestore, sehingga UI tidak tahu bedanya backend.

## 3. Security Rules (firestore.rules)

```
users/{uid}                    → hanya pemilik (request.auth.uid == uid)
users/{uid}/{tasks|notes|habits|chats}/{id}        → hanya pemilik
users/{uid}/…/{logs|messages}/{id}                 → hanya pemilik
```

Koleksi yang tidak terdaftar otomatis **ditolak** (deny by default). Deploy:

```bash
firebase deploy --only firestore:rules
```

## 4. Indeks Komposit (firestore.indexes.json)

- `tasks`: done ↑ + dueDate ↑ + createdAt ↓ (filter "hari ini/mendatang" + urutan)
- `notes`: pinned ↑ + updatedAt ↓ (urutan grid)

Index lain (orderBy tunggal) otomatis dibuat Firestore.

## 5. Operasi Data

| Aksi | Implementasi |
|---|---|
| Buat/ubah entitas | `set()` dengan id dari `uuid` (idempoten, aman offline) |
| Hapus banyak | batch 300 dokumen per commit |
| Hapus semua data | wipe tasks/notes/habits + subkoleksi logs/messages + dokumen user + `user.delete()` (tangani `requires-recent-login`) |
| Realtime | `.snapshots()` per koleksi; log kebiasaan di-listen per habit |
| Offline | Firestore persistence bawaan aktif; local mode tidak butuh jaringan |

## 6. Backup & Retensi

- Data milik user penuh; **hapus semua data** menghapus dokumen + akun auth.
- Cadangan: aktifkan **PITR (point-in-time recovery)** dan *scheduled backups* di console Firestore untuk produksi.
- Tidak ada data sensitif (token/key) yang disimpan di Firestore — API key Gemini hanya di perangkat user.
