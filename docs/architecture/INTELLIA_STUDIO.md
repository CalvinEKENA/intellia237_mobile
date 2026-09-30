# INTELLIA Studio — Windows control plane (foundation)

Sections G / H / I. This is the **architecture and migration plan first**, per the
mission — not a risky blind monorepo migration and not a superficial copy of the
mobile Admin UI. It defines the control-plane abstraction, the screen map and the
security model so the Studio UI can be built on a stable contract and the
persistence layer can be replaced later without rewriting the UI.

Everything user-visible in Studio is bilingual FR/EN via shared localized keys.
Studio never fabricates production metrics — real-but-empty data renders honest
empty states.

---

## G. INTELLIA Control Plane API abstraction

The Studio UI talks to an **INTELLIA Control Plane**, never to Firestore
collections/documents directly. The UI vocabulary is domain-level
(Establishments, Classes, Lessons, Audiences, Publishing…), not
`collection/doc`. Firebase remains infrastructure underneath the API.

```
INTELLIA Studio (Windows, Flutter desktop)
        |  (typed domain calls, no Firestore concepts)
INTELLIA Control Plane API
   AdminApi · ContentApi · PublishingApi · MediaApi
   ParentApi · SubscriptionApi · UsageApi · NotificationApi
        |  (server-authoritative)
Cloud Functions callables  ──►  Firestore / Storage
```

- **Privileged mutations go through server-authoritative Functions/API
  endpoints**, never unrestricted client Firestore writes. Reads may use scoped,
  rules-guarded queries; all *writes* that carry authority (publishing, role
  changes, subscription/allowance edits, establishment lifecycle) are callables.
- Each API is a Dart **interface** in a shared `intellia_api` package with:
  - a `*Api` abstract contract (methods return domain models, take domain inputs);
  - a `Firebase*Api` implementation calling callables;
  - a `Fake*Api` for tests and offline UI development.
- Replacing persistence = swapping the `Firebase*Api` implementations; the Studio
  UI and the `*Api` contracts do not change.

### API surface (initial contracts)

| API | Responsibility |
|---|---|
| `AdminApi` | establishments (create/inspect/edit/archive), classes (create/rename/metadata/archive/delete-if-safe), accounts & roles, staff attach/change establishment |
| `ContentApi` | subjects → chapters → lessons; block editing; quiz; FLOW; audiences; draft state |
| `PublishingApi` | the publishing workflow + version history + rollback (below) |
| `MediaApi` | media library, uploads to canonical `educational_assets/...`, **signed** URLs only |
| `ParentApi` | parents, linked children (read-only oversight; never global student search) |
| `SubscriptionApi` | plans / subscriptions |
| `UsageApi` | Study Reserve administration (allowance/cycle seeding, per-student reserve views) |
| `NotificationApi` | announcements + notifications |

### Repository strategy (recommended, staged — no blind migration)

```
intellia237_mobile/           # existing app (unchanged for this release)
intellia_studio/              # new Flutter desktop (Windows) app
packages/
  intellia_domain/            # pure domain models + logic (no Flutter, no Firebase)
  intellia_api/               # Control Plane contracts + Firebase/Fake implementations
  intellia_design_system/     # shared tokens/typography/components
```

Migration is **staged and reversible**, not a big-bang monorepo move:
1. **Extract** `intellia_domain` from the mobile app's pure domain (models, academic
   rules, Study Reserve logic) into a package; the mobile app depends on it.
2. **Extract** `intellia_design_system` (design_tokens, typography) similarly.
3. **Create** `intellia_api` with the contracts above, backed by the existing
   callables; the mobile app can adopt it incrementally where it already calls
   callables.
4. **Scaffold** `intellia_studio` depending on the three packages.
Each step ships independently and is revertible; the mobile release line is never
blocked on Studio.

---

## H. Studio screen map & desktop UX

Desktop shell: permanent **left navigation**, a top **global search / command
bar**, a central **workspace**, an optional right **contextual inspector**,
keyboard shortcuts, drag/drop where appropriate, multi-select + batch operations,
responsive window resizing, and **virtualized** large tables.

Modules (skeleton/navigation):

```
01 Login                     17 Quiz Studio
02 Command Center/Dashboard  18 Audiences
03 Establishments            19 Publishing Center
04 Establishment detail      20 Companions
05 School classes            21 Plans / Subscriptions
06 Students                  22 Study Reserve administration
07 Student detail            23 Payments / Mobile Money
08 Parents                   24 Notifications
09 Parent detail             25 Announcements
10 Teachers                  26 Analytics
11 Accounts & roles          27 System Health
12 Content Studio            28 Audit Log
13 Lesson editor             29 Global Settings
14 NotebookLM Import Center  30 Feature Flags
15 Media Library             31 Mobile Release visibility
16 FLOW Studio
```

- **Content Studio**: Subjects → Chapters → Lessons; block editing with a **live
  phone preview** (reuses the mobile `ContentBlockView` renderer via
  `intellia_design_system`, so the preview is truthful).
- **Publishing workflow** with version history and rollback:
  `Draft → Review → Approved → Scheduled → Published → Archived`. Every transition
  is an audited server action; each publish stores a version; rollback restores a
  prior version. `PublishingApi.transition(entityRef, from, to)` enforces the legal
  transitions server-side.
- **Study Reserve administration** (module 22): seed allowances per plan/cycle,
  inspect each student's product-safe reserve (never raw token counts), trigger a
  renewal. Consumes `UsageApi` over the Study Reserve backend already implemented
  (`functions/src/services/studyReserve.ts`).
- **Mobile Release visibility** (module 31): read-only view of the current
  versionName/versionCode and Play review state — never a publish control.
- **Honest empty states** everywhere: no fabricated metrics; an establishment with
  no classes, a student with no progress, an empty audit log all render explicit
  empty states.

---

## I. Control Plane security (RBAC + audit)

- **Server-enforced RBAC.** A client-side role check is never sufficient
  authorization: every privileged mutation re-derives the caller's role and scope
  from Firebase Auth + the user document inside the callable. Prepared roles:
  `superAdmin`, `schoolAdmin`, `pedagogicalManager`, `editor`, `reviewer`,
  `finance`, `support`. Each API method declares the minimum role/scope it
  requires; school-scoped roles are additionally bounded to their establishment.
- **Append-only audit** for sensitive actions: every publishing transition, role
  change, subscription/allowance edit, and establishment lifecycle change writes an
  immutable `audit_events` entry (`actorUid, action, targetRef, before/after
  summary, timestamp`) — server-only, never client-writable, never mutated or
  deleted.
- **Signed / temporary URLs** for protected media (already the model in
  `EducationalMediaService.resolveUrl` and the mobile PDF/audio/image paths). Studio
  reuses it; no permanent bearer URLs.
- **No service-account secrets in the desktop binary.** Studio authenticates as a
  normal Firebase user (the super-admin/editor account) and calls callables; it
  ships no service-account key. Privilege comes from the server-side RBAC on those
  callables, not from client credentials.

---

## Status

This document is the **foundation** deliverable (architecture + migration plan +
screen map + security model). The `intellia_studio` app and the `intellia_api` /
`intellia_domain` / `intellia_design_system` packages are to be scaffolded per the
staged plan above; the Study Reserve backend that module 22 consumes is already
implemented and tested (`docs/architecture/STUDY_RESERVE.md`).
