# NARA — Flutter Architecture

## 1. Gambaran

```
┌─────────────────────────── lib/ ────────────────────────────┐
│ main.dart        bootstrapping (Firebase→local fallback)    │
│ app.dart         MaterialApp.router + theme + l10n          │
│                                                             │
│ core/                                                       │
│  ├─ constants      AppConstants (Gemini model/key/endpoint) │
│  ├─ theme          Material 3 tokens, light+dark            │
│  ├─ router         go_router + redirect guard               │
│  ├─ providers      DI: store, bootstrap, repos, AI key      │
│  ├─ storage        LocalStore (SharedPreferences reactive)  │
│  ├─ models         Task/Note/Habit/ChatMessage/UserProfile  │
│  ├─ repositories   Disabled* no-op impls                    │
│  ├─ ai             AssistantEngine (on-device) + GeminiService│
│  ├─ notifications  ReminderService (daily reminder)         │
│  └─ widgets        NaraCard, GradientButton, EmptyState, …  │
│                                                             │
│ features/  (feature-first)                                  │
│  ├─ auth           AuthRepository → Firebase | Local + UI   │
│  ├─ onboarding, splash, shell                               │
│  ├─ dashboard      beranda + saran AI                       │
│  ├─ chat           ChatController (hybrid orchestrator)     │
│  ├─ tasks          TaskRepository → Firebase | Local + UI   │
│  ├─ notes          NoteRepository → Firebase | Local + UI   │
│  ├─ habits         HabitRepository → Firebase | Local + UI  │
│  ├─ profile        pengaturan + sheets                      │
│  ├─ settings       PrefsController (theme/language/reminder)│
│  └─ data           StreamProvider bersama lintas fitur      │
└─────────────────────────────────────────────────────────────┘
```

## 2. Prinsip

- **Feature-first + clean layering**: UI tidak pernah menyentuh Firestore/SharedPreferences langsung — semua lewat interface repositori.
- **Dependency Inversion**: `AuthRepository`, `TaskRepository`, `NoteRepository`, `HabitRepository`, `ChatRepository` adalah interface dengan implementasi **Firebase** (produksi) dan **Local** (demo/offline) serta **Disabled** (no-op sementara auth belum resolve di mode Firebase).
- **DRY**: model punya `toMap/fromMap` tunggal untuk Firestore & JSON lokal; kit widget (NaraCard, GradientButton, EmptyState, StatTile, Entrance) dipakai semua layar.
- **State**: Riverpod 2 — `StreamProvider` untuk data reaktif (repositories memancarkan stream), `Notifier` untuk state aplikatif (prefs, chat UI, ai key, onboarding). Tidak ada `StatefulWidget` untuk state global.
- **Navigasi**: `go_router` dengan `StatefulShellRoute.indexedStack` (state tab terjaga) + redirect deklaratif (splash → onboarding → auth → shell).

## 3. Hybrid AI Strategy

```
User message
     │
     ├─ key Gemini tersedia? ── ya ─▶ GeminiService.generateReply()
     │        │                        (system prompt + konteks user +
     │        │                         10 giliran terakhir, timeout 25s)
     │        │                      gagal (key invalid/kuota/jaringan)?
     │        │                        └─▶ fallback ke engine lokal + banner
     │        └─ tidak ─▶ AssistantEngine.respond()
     │
     └─ AssistantEngine (on-device, deterministic, bilingual)
         intent: buat tugas (+parse tanggal/jam/weekday, kutipan judul),
         catat note, check-in habit, list tugas, status kebiasaan,
         bantuan, persona, waktu, motivasi, sapaan, fallback
         → AssistantReply { text, actions[] }
              actions dieksekusi ChatController:
              CreateTaskAction → TaskRepository.add
              CreateNoteAction → NoteRepository.add
              CheckInHabitAction → HabitRepository.toggleLog
```

- Tier 1 selalu hidup: **offline, latensi ~0 ms, bisa mengeksekusi aksi**.
- Tier 2 menambah jawaban terbuka; sistem prompt menyuntikkan konteks (tugas terbuka, nama) dan aturan bahasa (balas bahasa user).
- `dailySuggestion()` memakai mesin yang sama untuk kartu saran di Beranda.

## 4. Mode Operasi

| | **Firebase mode** (produksi) | **Local mode** (fallback) |
|---|---|---|
| Deteksi | `Firebase.initializeApp()` sukses | exception saat init |
| Auth | Firebase Auth + Google Sign-In | profil perangkat (tanpa kredensial) |
| Data | Firestore realtime + offline persistence | SharedPreferences JSON + stream |
| Badge UI | 🟢 Sinkron cloud | 🟠 Mode lokal (banner di auth) |

Keputusan diambil **sekali di `main()`** dan disuntikkan lewat `appBootstrapProvider`; seluruh provider repositori membaca flag ini — tidak ada `if (firebase)` tersebar di UI.

## 5. Alur Boot

```
main()
 ├─ SharedPreferences → LocalStore
 ├─ Firebase.initializeApp()? → FirebaseAuthRepository : LocalAuthRepository
 ├─ ReminderService.init() (+ restore jadwal harian)
 └─ runApp(ProviderScope(overrides: [store, bootstrap], child: NaraApp))
      └─ GoRouter: /splash → (onboarding?) → (login?) → /home
```

## 6. Testing Strategy

- **Unit**: `AssistantEngine` (intent ID/EN, parsing tanggal/kutipan), streak kebiasaan, filter tugas, model round-trip.
- **Repositori**: LocalTask/LocalHabit (CRUD + toggle log + cascade delete) dengan SharedPreferences mock.
- **Widget smoke**: TasksScreen local-mode — empty state & alur tambah-tampil via repositori nyata.
- CI (`.github/workflows/ci.yml`): analyze + test + build APK debug di setiap push/PR.

## 7. Konvensi Kode

- `flutter_lints` penuh — `flutter analyze` bersih (0 temuan).
- Nama: kelas `PascalCase`, file `snake_case`, konstanta `lowerCamelCase`.
- Semua string UI lewat `AppLocalizations` (ARB `lib/l10n/app_{en,id}.arb`).
- Error tidak pernah ditelan diam-diam: fallback yang jelas (mode lokal, engine lokal) + pesan user; `catch (_) {}` kosong dilarang.
