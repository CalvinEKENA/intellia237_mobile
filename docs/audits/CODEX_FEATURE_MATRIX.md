# Codex Feature Matrix - Intellia237 Mobile

Date: 2026-06-18  
Legend: Ready = usable after normal QA; Partial = real implementation exists but has gaps; Demo = mock/demo-backed; Blocked = cannot be validated because of current blocker; Missing = not found in tracked repository.

| Feature | Status | Frontend Evidence | Backend/Data Source | Main Gap |
| --- | --- | --- | --- | --- |
| App bootstrap | Partial | `lib/main.dart`, `lib/bootstrap.dart`, `lib/app/app.dart` | Firebase init and onboarding preferences | Firebase options are not passed explicitly; compile blocker prevents clean validation. |
| Theme and Material shell | Blocked | `lib/app/theme/app_theme.dart` | Local Flutter theme only | `CupertinoPageTransitionsBuilder` unresolved at lines 97-98. |
| Route guards | Partial | `lib/app/router/app_router.dart`, `lib/app/router/app_routes.dart` | Auth controller and onboarding provider | Needs integration tests for each role transition and unauthorized path. |
| Onboarding | Partial | `lib/features/onboarding/**` | SharedPreferences via onboarding preferences | Needs product-brand migration and visual QA. |
| Login/logout/password reset | Partial | `lib/features/auth/**` | FirebaseAuth + `users` collection | Needs auth emulator tests, role edge cases, and failure UX coverage. |
| Student registration | Partial | `lib/features/student_registration/**` | FirebaseAuth, `users`, `student_profiles`, local establishment data | Uses bundled establishment mock data; rules and rollback need tests. |
| Parent registration | Partial | `lib/features/parent_registration/**` | FirebaseAuth, `users`, `parent_profiles` | Parent-child link workflow is not fully proven end to end. |
| Teacher registration | Partial | `lib/features/teacher_registration/**` | FirebaseAuth, `users`, `teacher_profiles` | Approval/verification policy needs product decision and tests. |
| Admin registration | Partial | `lib/features/admin_registration/**` | FirebaseAuth, `users`, `admin_profiles` | Security policy around admin creation must be tightened and tested. |
| Student dashboard/home | Demo | `lib/features/student_home/**` | `DemoStudentHomeRepository` | Demo data; not production-backed. |
| Learn hub | Partial | `lib/features/learn/application/learn_providers.dart`, `firestore_learn_repository.dart` | Firestore classes/subjects/chapters/lessons/progress | Needs indexes, pagination, data-volume tests, and server-authoritative progress strategy. |
| Lesson viewer | Partial | `lib/features/learn/presentation/lesson_viewer_screen.dart` | Firestore lesson documents and progress writes | Large file, client progress writes, and no offline/cache strategy observed. |
| Quiz catalog | Partial | `lib/features/quiz/data/firestore_quiz_repository.dart` | Firestore `quizzes` | Needs pagination/indexing and content publication workflow validation. |
| Quiz play/result | Critical risk | `lib/features/quiz/presentation/quiz_play_screen.dart`, `quiz_result_screen.dart` | Client builds attempt payload, Firestore attempt service writes XP | XP and attempts must move to trusted backend before production. |
| Generated quizzes | Partial | `lib/features/tutor/data/structured_ai_functions_service.dart` | Callable `generateQuiz`, `courses/{courseId}/generated_quizzes` | Functions build/tests pass, but LLM provider and quota controls are unresolved. |
| Generated summaries | Partial | `structured_ai_functions_service.dart` | Callable `generateSummary`, `courses/{courseId}/generated_summaries` | Same AI provider/cost/security gaps as generated quizzes. |
| AI companion chat | Partial | `lib/features/ai_companion/**` | Callable `askTutor` | Retrieval can pull wrong lessons; prompt/input bounds and quota controls need work. |
| Tutor selection | Not aligned | `lib/features/tutor/domain/tutor_persona.dart`, `tutor_selection_screen.dart` | Hard-coded local personas/assets | Kira/Leo target is missing; current personas and assets are Edunova-specific. |
| Admin content studio | Partial | `lib/features/admin/application/admin_content_providers.dart` | Direct Firestore CRUD | Needs server-side validation, audit trail, moderation policy, and rules tests. |
| Admin dashboard/moderation | Demo | `lib/features/admin/data/mock_admin_repository.dart` | Mock repository | Replace with real analytics/moderation data or hide from production. |
| Parent portal | Demo | `lib/features/parent/**` | `MockParentRepository` | Not production-backed. |
| Teacher portal | Demo | `lib/features/teacher/**` | `MockTeacherRepository` | Not production-backed. |
| Profile/avatar picker | Partial | `lib/features/profile/widgets/avatar_picker_widget.dart` | Firebase Storage `avatars/{uid}` | Needs upload constraints, image processing, and moderation decision. |
| Notifications | Partial schema only | Firestore rules define `notifications` | Writes are Functions-only in rules | No observed notification Function or delivery pipeline. |
| Recommendations | Partial schema only | Firestore rules define `recommendations` | Reads/updates by student, creates denied to client | No observed recommendation generation pipeline. |
| Reports | Partial schema only | Firestore rules define `reports` | Staff-created according to rules | No complete reporting pipeline validated. |
| Payments/subscriptions | Missing | No tracked feature directory found | No payment provider or credit ledger found | Required if AI usage is monetized or quota-limited by plan. |
| CI/CD | Missing | No `.github` directory found | None | Add CI before release work. |
| Firebase rules tests | Missing | No rules test suite found | Emulator rules tests absent | Required before public beta. |
| Python LLM microservice | Missing | No `llm-service/` directory found | Not present | README and requested target need reconciliation with actual backend. |

## Data Collections Observed From Rules And Code

| Collection/Path | Current Writers | Production Concern |
| --- | --- | --- |
| `users/{uid}` | Owner, admins, super admins | Role/establishment mutation policy needs stricter tests. |
| `student_profiles/{uid}` | Owner, admins, super admins | XP/progress profile fields should not be owner-trusted if used for ranking. |
| `student_profiles/{uid}/lessonProgress/{progressId}` | Owner | Academic progress integrity risk. |
| `parent_profiles/{uid}` | Owner, super admin | Needs parent-child workflow tests. |
| `teacher_profiles/{uid}` | Owner, admin, super admin | Teacher approval and establishment scope need validation. |
| `admin_profiles/{uid}` | Super admin create, owner/super admin update | Admin onboarding is sensitive. |
| `children_links/{linkId}` | Parent create, admin/super admin update | Approval flow must be tested. |
| `classes`, nested `subjects`, `chapters`, `lessons` | Staff roles | Needs schema validation and content workflow. |
| `courses/{courseId}` and `courses/{courseId}/images` | Staff roles | Storage writes are denied; ingestion path should stay backend/admin. |
| `courses/{courseId}/generated_quizzes` | Cloud Functions only | Good boundary, but LLM costs and provider mismatch remain. |
| `courses/{courseId}/generated_summaries` | Cloud Functions only | Good boundary, same AI gaps. |
| `quizzes/{quizId}` | Staff roles | Publication and moderation workflow needed. |
| `quiz_attempts/{attemptId}` | Student owner can create/update | Critical integrity risk. |
| `progress/{progressId}` | Student owner can create/update | Integrity risk if authoritative. |
| `badges/{badgeId}` | Admin/super admin | Badge awards pipeline not fully observed. |
| `streaks/{uid}` | Owner can create/update | Can be fabricated by client. |
| `ai_conversations/{conversationId}` | User owner | Needs retention/privacy/cost controls. |
| `notifications/{notificationId}` | Functions-only create | Delivery pipeline not observed. |
| `recommendations/{recommendationId}` | Functions/AI-only create by rules | Generation pipeline not observed. |
| `reports/{reportId}` | Staff roles | Needs report generation and access tests. |
| `settings/{uid}` | Owner | Acceptable if only preferences. |

## Quality Status By Layer

| Layer | Status | Verified Result |
| --- | --- | --- |
| Local Flutter environment | Ready | `flutter doctor -v` passed. |
| Flutter dependencies | Partial | `flutter pub get` passed but lockfile changed under current toolchain and dependencies are behind. |
| Dart formatting | Failing | 71 Dart files would be reformatted. |
| Flutter static analysis | Failing | 5 errors in `app_theme.dart`. |
| Flutter tests | Failing | Widget test cannot compile. |
| Functions install | Partial | Install succeeds, but Node engine mismatch and npm vulnerabilities exist. |
| Functions unit tests | Passing | 5/5 tests pass. |
| Functions build | Passing | TypeScript build passes. |
| CI | Missing | No workflow directory found. |

