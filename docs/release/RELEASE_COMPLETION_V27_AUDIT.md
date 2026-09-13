# RELEASE COMPLETION v3.2.1+27 — Pre-modification audit

- **Branch:** `fix/release-completion-v27` (from production baseline `1981078` — `fix: restore media UTF-8 and allow production identifiers`).
- **Firebase project:** `edunova-aabd1` (unchanged). Package id `com.edunova.app` (unchanged). Version `3.2.1+27` (unchanged).
- **Method:** marker sweep (`TODO/FIXME/UnsupportedError/placeholder/mock/simulated/fake/hardcoded/"Aucun fichier enregistré"/"Phase 2"/not implemented`) across `lib/` and `functions/src`, then targeted reading of every functional area (admin, parent, auth, student, teacher, Content Studio, FLOW, Learn, quiz, media, NotebookLM, payments, notifications, profile/settings, routing, Firestore/Storage rules, Functions).
- **Legend:** 🔴 BLOCKER · 🟠 HIGH · 🟡 MEDIUM · ⚪ ACCEPTED-NON-BLOCKER.

The Functions backend (`functions/src`) is mature and clean: no `TODO`/`not implemented`/dead paths in source (all marker hits are in `__tests__` `vi.mock(...)` or the legitimate `engineMode: z.enum(["mock","vertex-ai"])` dev engine). Many server-authoritative callables already exist (`learningCatalogCallable`, `lessonPublicationCallable`, `quizContentCallables`, `academicCallables`, `educationalMedia`, `flowCatalog`, `mobileMoneyCallables`, `adminAccountManagementCallable`, `accountEstablishmentChangeCallable`, `accountDeletionCallable`, …).

---

## 🔴 BLOCKERS

### C-1 — Parent↔child linking is broken end-to-end (empty dashboard forever)
- **Evidence:**
  - Registration writes the requested children into `parent_profiles/{uid}.linkedChildren` (array) + `linkedChildrenCount` — [parent_registration_payload.dart:51-59](lib/features/role_registration/domain/parent_registration_payload.dart:51).
  - Parent dashboard reads **only** approved `children_links` documents (`where parentId == uid`, `status == 'approved'`, field `studentId`) — [firestore_parent_repository.dart:22-45](lib/features/parent/data/firestore_parent_repository.dart:22).
  - **Nothing ever creates a `children_links` document.** A repo-wide search for `children_links` returns only: this dashboard read, `firestore_admin_repository._linkedChildren` (admin read), `mobileMoneyCallables.ts` (read), and a rules test. There is **no** `linkChild`/`resolveChild` callable and no client write path.
- **Impact:** every parent who registers with a child code sees an empty "Mes enfants" / dashboard indefinitely. The `linkedChildren` array is orphaned data.
- **Secondary gap:** no canonical student invitation/public-code mechanism exists in the student model (searched `student_registration/domain` — only `contentLanguage.code`, no student-facing link code). Section C must therefore *establish* the canonical identifier server-side, not reuse a non-existent one.
- **Secondary gap:** no "add a child after registration" action is wired — parent home only shows the `linkChildHelp` string and an `addLearner` ("Ajouter un enfant") label ([parent_home_screen.dart:301](lib/features/parent/presentation/parent_home_screen.dart:301)); no linking form/callable behind it.
- **Fix direction (section C):** server-authoritative callable that resolves a child code → creates a canonical idempotent `children_links` doc (pending/approved), never exposing a student directory; parent add-child UI (registration + "Mes enfants"); safe migration of legacy `linkedChildren`; rules stay scoped; full test matrix.

---

## 🟠 HIGH

### B-1 — Super-admin → Parent preview is not implemented, and routing blocks it
- **Evidence:**
  - `AppRole` has only `student/parent/teacher/admin` — super-admin is a **flag**, not a role (mission: `isSuperAdmin` + normalized email `calvinekena4@gmail.com`).
  - The router redirect actively **prevents** a non-parent from reaching parent routes: [app_router.dart:603-605](lib/app/router/app_router.dart:603) (`if (role != AppRole.parent && AppRoutes.isParentPath(location)) return expectedHome;`).
  - No preview-mode state, no gate (`isSuperAdmin && normalizedEmail == calvinekena4@gmail.com`), no target-parent selection, no "Prévisualisation Parent" banner, no return-to-Admin path.
- **Fix direction (section B):** an explicit experience/preview mode **separate from authorization** (real `AuthState` role stays `superAdmin`); router permits parent routes only while preview is active; gated strictly; optional target-parent UID for dashboard load; mutation-sensitive controls (payments) read-only/unavailable while impersonating; sign-out clears preview; full test set.

### F-1 — NotebookLM generic wizard is a hard-coded dead-end
- **Evidence:** `_import()` sets `_outcome = 'Aucun fichier enregistré. Ouvrez une leçon en brouillon…'` and advances to the result step **without any upload or persistence** — [notebooklm_import_wizard_screen.dart:105-111](lib/features/admin/presentation/notebooklm_import_wizard_screen.dart:105).
- **Nuance:** a *real* persistent path already exists when the wizard is opened **from a draft lesson** — it delegates to `VideoImportScreen(lesson, notebook: true)` ([:113-122](lib/features/admin/presentation/notebooklm_import_wizard_screen.dart:113)). Only the generic (no-target-lesson) entry dead-ends.
- **Fix direction (section F):** in the generic path, let the admin pick an existing draft lesson (or create a new draft in the chosen chapter), then upload to the canonical `educational_assets/{scope}/{class}/{subject}/{lesson}/{asset}/{file}` path and attach to the draft (no auto-publish). Prove persistence with tests. Supported artifacts: image / MP4 / audio / PDF.

### H-1 — Rich course text renders raw Markdown to students
- **Evidence:** `TextBlock` renders `block.markdown` inside a plain `Text` widget — [content_block_view.dart:84-92](lib/features/learn/presentation/widgets/content_block_view.dart:84). Headings, bold/italic, lists, code, links, quotes all appear as literal syntax. No markdown renderer and no `flutter_markdown`-style dependency in `pubspec.yaml`.
- **Fix direction (section H):** safe rich renderer (headings/paragraphs/bold/italics/lists/numbered/inline code/safe links/blockquote/simple formulas), width ≥ 320, textScale ≤ 2.0, FR/EN, scroll not clip, no raw syntax leakage.

### G-1 — Lesson media: audio and PDF are non-functional placeholders
- **Evidence:** in `_MediaSurface`, `MediaType.audio` and `MediaType.pdf` both return `_MediaPlaceholder` (icon + label only, no player/viewer) — [content_block_view.dart:144-161](lib/features/learn/presentation/widgets/content_block_view.dart:144).
  - **Audio capability exists but is unwired:** `AudioOverviewPlayer` + `JustAudioEngine` (real `just_audio`, play/pause/seek/speed, engine abstraction with a fake for tests) — [audio_overview_player.dart:1-55](lib/features/learn/presentation/widgets/audio_overview_player.dart:1). MediaBlock audio must be routed to a real player.
  - **PDF has no viewer at all** (no PDF package in `pubspec.yaml`): needs a secure in-app viewer or a signed-URL temporary-file open flow.
  - **Image is complete** ✅ — `_RemoteImage` resolves a signed URL at display time (never stored), with loading + error fallback ([:170-206](lib/features/learn/presentation/widgets/content_block_view.dart:170)). Video is complete ✅ (`EducationalVideoPlayer`).
- **Fix direction (section G):** wire MediaBlock audio to the existing player (no autoplay, lifecycle pause, retry/error, a11y); add a real PDF workflow (no permanent bearer URLs); keep image as-is; tests for each.

---

## 🟡 MEDIUM

### E-1 — Establishment / School-class CRUD incomplete
- **Evidence:** `createEstablishment` exists ([firestore_admin_repository.dart:525](lib/features/admin/data/firestore_admin_repository.dart:525), surfaced via [attach_school_sheet.dart:84](lib/features/admin/presentation/attach_school_sheet.dart:84)). School **class** currently supports **rename only** (`_RenameClassDialog`, [school_directory_section.dart:247-307](lib/features/admin/presentation/school_directory_section.dart:247)). Campus repo exposes `updateStaffStatus`, `updateTeachingPlanStatus` ([campus_repository_contracts.dart](lib/features/campus/domain/repositories/campus_repository_contracts.dart)).
- **Missing (section E):** create class; archive/delete **empty** class with attached-student guard; establishment edit (name/city/metadata) + archive/deactivate without orphaning; establishment-scope enforcement; canonical levels kept canonical (not conflated with class labels like "6e A"). Needs verification of staff validation/attach/change-establishment/suspension coverage.

### E-2 — Dead code (not user-facing; cleanup)
- `RolePlaceholderScreen` is defined but **never routed** (no instantiation anywhere) — [role_placeholder_screen.dart](lib/features/dashboard/presentation/role_placeholder_screen.dart). Real homes exist for every role; safe to remove or keep as an explicit fallback.
- `AdminContentRepository.generateLessonContent` / `generateQuizQuestions` **throw `UnsupportedError`** and are **never called** (client-side AI removed in favour of the backend) — [admin_content_providers.dart:404-422](lib/features/admin/application/admin_content_providers.dart:404). Dead code.

### I-1 — Regression surface to re-verify (section I)
After any rules/callable changes: student FLOW uses `readLearningCatalog` (never direct `flow_items` reads); admin/editorial FLOW uses server paths; lesson/quiz audience resolution; media authorization; legacy text lessons still readable; V1/V2 dual-write backward-safe. To be exercised by the existing suites + new tests.

---

## ⚪ ACCEPTED-NON-BLOCKER

- `video_file_controller_stub.dart` `UnsupportedError` — conditional-import stub for unsupported platforms (correct pattern) — [:4](lib/features/learn/presentation/widgets/video_file_controller_stub.dart:4).
- `firebase_options.dart` `UnsupportedError` — generated unsupported-platform guards.
- Honest empty/coming-soon states are intended UX, not dead-ends: `stateComingSoonTitle`, `chaptersComingTitle/Body`, `activityChartComing`, `metricComingSoon`.
- LLM `engineMode: "mock"` — legitimate dev/test engine selector in `functions/src/llm/schemas.ts`.
- `demo_campus_repository` "deterministic fake draft questions" — a demo/dev repository (verify it is not bound in the production provider graph; if bound, promote to a finding).
- Search UI `hintText: searchPlaceholder` — form placeholder text, not a stub.

---

## Section J — Firebase release safety (follow-ups, non-blocking)

- **Do not delete** existing remote-only functions: `chatWithDavid`, `generateExercises`, `gradeAnswer` (us-central1) — absent from local source, must remain untouched.
- **Technical follow-up (do NOT bundle into this release):** Node.js 20 runtime decommissioning before **2026-10-30**; `firebase-functions` upgrade from `^6.0.1`. Track separately (potentially breaking).

---

## Proposed execution order (blockers first, each committed as a logical unit with tests)

1. **B** — super-admin Parent preview (contract + router gate + banner + target-parent + read-only mutations) `+ tests`.
2. **C** — server-authoritative parent↔child linking (callable + canonical `children_links` + add-child UI + legacy migration) `+ tests + rules tests`.
3. **D** — verify/complete the whole Parent experience `+ parent test suite` (sizes 320–600+, textScale 1.0–2.0, FR/EN, multi/no children, offline, deleted child).
4. **F** — NotebookLM real persistent import (generic path) `+ tests`.
5. **G** — audio wiring + PDF workflow `+ tests`.
6. **H** — safe Markdown rich text `+ tests`.
7. **E** — establishment/class CRUD completion `+ tests`.
8. **I/K** — regression + full quality suite green (dart format, brand, analyze, flutter test, functions npm test/build, firestore+storage rules tests).

**Verdict at audit stage: NOT READY** — one 🔴 blocker (C) and four 🟠 highs (B, F, H, G) block a clean release. No code has been modified yet (audit only).
