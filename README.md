# EDUNOVA AI Backend

Backend Firebase + microservice LLM pour EDUNOVA, avec appels strictement structurés, authentification Firebase obligatoire et génération basée uniquement sur les contenus de Firestore/Storage.

## Architecture

- `Flutter/Web` appelle uniquement `Cloud Functions 2nd gen`
- `Cloud Functions` vérifie `Firebase Auth`, lit `Firestore` et `Storage`, puis appelle le microservice LLM
- `FastAPI` construit les prompts serveur et renvoie du JSON strict
- `Firestore` stocke les cours, les métadonnées d'images, les quiz générés et les résumés générés
- `Firebase Storage` stocke les images de cours sous `courses/{courseId}/images/`
- `Google Drive` reste la source d'ingestion initiale

Le client ne voit jamais le prompt. Le client ne contacte jamais le LLM directement.

## Arborescence

```text
edunova/
├─ firebase.json
├─ .firebaserc
├─ firestore.rules
├─ firestore.indexes.json
├─ storage.rules
├─ functions/
│  ├─ .env.example
│  ├─ package.json
│  ├─ tsconfig.json
│  ├─ vitest.config.ts
│  ├─ scripts/
│  │  └─ pregenerate.ts
│  └─ src/
│     ├─ config/
│     │  ├─ env.ts
│     │  └─ firebase.ts
│     ├─ http/
│     │  └─ llmClient.ts
│     ├─ llm/
│     │  └─ contracts.ts
│     ├─ models/
│     │  └─ course.ts
│     ├─ repositories/
│     │  ├─ courseRepository.ts
│     │  └─ generatedContentRepository.ts
│     ├─ services/
│     │  ├─ generateQuizUseCase.ts
│     │  ├─ generateSummaryUseCase.ts
│     │  └─ llmPayloadFactory.ts
│     ├─ utils/
│     │  ├─ errors.ts
│     │  └─ validation.ts
│     ├─ __tests__/
│     │  ├─ llmPayloadFactory.test.ts
│     │  └─ validation.test.ts
│     └─ index.ts
├─ llm-service/
│  ├─ .env.example
│  ├─ pyproject.toml
│  ├─ app/
│  │  ├─ config.py
│  │  ├─ json_utils.py
│  │  ├─ main.py
│  │  ├─ models.py
│  │  ├─ prompt_builders.py
│  │  ├─ engines/
│  │  │  ├─ base.py
│  │  │  ├─ mock.py
│  │  │  └─ openai_compatible.py
│  │  ├─ routers/
│  │  │  └─ generation.py
│  │  └─ services/
│  │     └─ generation_service.py
│  └─ tests/
│     └─ test_api.py
├─ scripts/
│  ├─ requirements.txt
│  ├─ ingest_drive_to_storage.py
│  ├─ seed_sample_course.py
│  └─ smoke_test.py
├─ samples/
│  └─ firestore/
│     └─ course.sample.json
└─ lib/
   └─ features/
      └─ tutor/
         └─ data/
            └─ structured_ai_functions_service.dart
```

## Collections Firestore

- `courses/{courseId}`
- `courses/{courseId}/images/{imageId}`
- `courses/{courseId}/generated_quizzes/{quizId}`
- `courses/{courseId}/generated_summaries/{summaryId}`

## Variables d'environnement

### `functions/.env.local`

```env
FUNCTIONS_REGION=europe-west1
FIREBASE_STORAGE_BUCKET=edunova-aabd1.firebasestorage.app
LLM_SERVICE_BASE_URL=http://127.0.0.1:8000
LLM_SERVICE_API_KEY=change-me
LLM_SERVICE_TIMEOUT_MS=45000
MAX_COURSE_IMAGES=8
LOG_LEVEL=info
```

### `llm-service/.env`

```env
EDUNOVA_HOST=0.0.0.0
EDUNOVA_PORT=8000
EDUNOVA_LOG_LEVEL=INFO
EDUNOVA_LLM_MODE=gemini
EDUNOVA_LLM_TIMEOUT_SECONDS=45
EDUNOVA_SERVICE_API_KEY=change-me

# Gemini API
GEMINI_API_KEY=your-gemini-api-key
GEMINI_MODEL=gemini-3.1-flash-preview
GEMINI_FALLBACK_MODEL=gemini-2.5-flash
```

### Variables shell locales utiles

```powershell
$env:FIREBASE_PROJECT_ID="edunova-aabd1"
$env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9100"
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8085"
$env:FIREBASE_STORAGE_EMULATOR_HOST="127.0.0.1:9200"
$env:FUNCTIONS_BASE_URL="http://127.0.0.1:5005"
```

## Installation

### 1. Functions

```powershell
cd C:\projets\FlutterProjects\edunova\functions
npm install
Copy-Item .env.example .env.local
```

### 2. Microservice LLM

```powershell
cd C:\projets\FlutterProjects\edunova\llm-service
py -3.13 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -e .[dev]
Copy-Item .env.example .env
```

### 3. Scripts Python

```powershell
cd C:\projets\FlutterProjects\edunova
python -m pip install -r scripts\requirements.txt
```

### 4. Flutter

```powershell
cd C:\projets\FlutterProjects\edunova
flutter pub get
```

## Lancement local

### Terminal 1: microservice LLM

```powershell
cd C:\projets\FlutterProjects\edunova\llm-service
.\.venv\Scripts\Activate.ps1
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### Terminal 2: Firebase emulators

```powershell
cd C:\projets\FlutterProjects\edunova
firebase emulators:start --config firebase.json --only auth,firestore,functions,storage --project edunova-aabd1
```

### Terminal 3: seed des données d'exemple

```powershell
cd C:\projets\FlutterProjects\edunova
$env:FIREBASE_PROJECT_ID="edunova-aabd1"
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8085"
python scripts\seed_sample_course.py
```

## Tests

### Tests Functions

```powershell
cd C:\projets\FlutterProjects\edunova\functions
npm test
```

### Tests microservice

```powershell
cd C:\projets\FlutterProjects\edunova\llm-service
.\.venv\Scripts\Activate.ps1
pytest
```

### Smoke test bout en bout

Pré-requis:

- microservice actif sur `http://127.0.0.1:8000`
- emulators Firebase actifs
- données d'exemple seedées

Commande:

```powershell
cd C:\projets\FlutterProjects\edunova
$env:FIREBASE_PROJECT_ID="edunova-aabd1"
$env:FIREBASE_AUTH_EMULATOR_HOST="127.0.0.1:9100"
$env:FIRESTORE_EMULATOR_HOST="127.0.0.1:8085"
$env:FUNCTIONS_BASE_URL="http://127.0.0.1:5005"
python scripts\smoke_test.py
```

## Déploiement Cloud Run du microservice

Exemple minimal:

```powershell
cd C:\projets\FlutterProjects\edunova\llm-service
gcloud run deploy edunova-llm-service `
  --source . `
  --region europe-west1 `
  --allow-unauthenticated `
  --set-env-vars EDUNOVA_LLM_MODE=gemini,GEMINI_API_KEY=your-api-key,EDUNOVA_SERVICE_API_KEY=change-me
```

Ensuite pointer `functions/.env.local` et les variables de déploiement Functions vers l'URL Cloud Run.

## Déploiement Firebase Functions

```powershell
cd C:\projets\FlutterProjects\edunova
firebase deploy --only functions
```

## Ingestion Google Drive -> Firebase Storage

Le script:

- liste les images d'un dossier Drive
- gère la pagination
- reprend à partir d'un fichier d'état JSON
- envoie chaque image vers `courses/{courseId}/images/`
- écrit les métadonnées dans `courses/{courseId}/images/{imageId}`

Exemple:

```powershell
cd C:\projets\FlutterProjects\edunova
$env:FIREBASE_PROJECT_ID="edunova-aabd1"
$env:FIREBASE_STORAGE_BUCKET="edunova-aabd1.firebasestorage.app"
python scripts\ingest_drive_to_storage.py `
  --course-id course_demo_sciences_001 `
  --drive-folder-id YOUR_DRIVE_FOLDER_ID `
  --continue-on-error
```

Pré-requis:

- `GOOGLE_APPLICATION_CREDENTIALS` pointe vers un service account autorisé sur Drive, Firestore et Storage
- API Google Drive activée
- pour les emulators Firestore/Storage récents, `firebase-tools` demande un JDK 21+

## Pré-génération massive

Le script `functions/scripts/pregenerate.ts` réutilise exactement les mêmes use cases que les callable functions.

Exemple:

```powershell
cd C:\projets\FlutterProjects\edunova\functions
npm run pregenerate -- --courseId course_demo_sciences_001 --count 6 --difficulty medium --level standard
```

## Exemple d'appel Flutter

Le client Flutter doit utiliser `StructuredAiFunctionsService`:

```dart
final service = StructuredAiFunctionsService();

final quiz = await service.generateQuiz(
  courseId: 'course_demo_sciences_001',
  count: 5,
  difficulty: 'medium',
);

final summary = await service.generateSummary(
  courseId: 'course_demo_sciences_001',
  level: 'standard',
);
```

Fichier complet: `lib/features/tutor/data/structured_ai_functions_service.dart`

## Notes de sécurité

- Auth Firebase exigée dans `generateQuiz` et `generateSummary`
- prompts construits uniquement côté backend
- microservice protégé par `X-Edunova-Service-Key`
- réponses LLM validées côté microservice et côté Functions
- Storage course images en écriture serveur uniquement
- règles Firestore prévues pour les collections générées

## Checklist de vérification

1. `npm test` passe dans `functions/`
2. `pytest` passe dans `llm-service/`
3. `uvicorn app.main:app` démarre sans erreur
4. `firebase emulators:start` démarre avec Auth, Firestore, Functions et Storage
5. `python scripts\seed_sample_course.py` crée `courses/course_demo_sciences_001`
6. `python scripts\smoke_test.py` renvoie un quiz JSON et un résumé JSON
7. `python scripts\ingest_drive_to_storage.py ...` crée les fichiers Storage et les métadonnées Firestore
8. Le frontend Flutter peut appeler `generateQuiz` et `generateSummary` via `cloud_functions`
9. Aucun appel direct au LLM n'est présent côté client dans le nouveau flux
