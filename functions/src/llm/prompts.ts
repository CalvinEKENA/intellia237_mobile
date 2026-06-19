import { CourseContext, GenerateQuizRequest, GenerateSummaryRequest } from "./schemas";

function renderImages(images: CourseContext["images"]): string {
  if (!images || images.length === 0) {
    return "Aucune image associee.";
  }

  return images.map((image) => {
    const parts = [
      `- id=${image.id}`,
      `file=${image.fileName}`,
      `path=${image.storagePath}`,
    ];
    if (image.caption) parts.push(`caption=${image.caption}`);
    if (image.ocrText) parts.push(`ocr=${image.ocrText}`);
    return parts.join(" | ");
  }).join("\n");
}

function renderCourseContext(course: CourseContext): string {
  const objectives = course.learningObjectives?.map((o) => `- ${o}`).join("\n") || "- Aucun objectif";
  const tags = course.tags?.join(", ") || "aucun tag";
  const sections = course.contentSections.map((s, i) => `[Section ${i + 1}] ${s.title}\n${s.body}`).join("\n\n");
  const images = renderImages(course.images);

  return `Cours: ${course.title}
Matiere: ${course.subject}
Niveau: ${course.gradeLevel}
Langue: ${course.language}
Tags: ${tags}
Objectifs:
${objectives}

Contenu:
${sections}

Images:
${images}`;
}

export const QUIZ_SYSTEM_PROMPT = `Tu es un tuteur pédagogique ultra sympa, dynamique et amical pour INTELLIA237.
Tu t'adresses toujours à l'élève en le tutoyant ("tu", "ton", "ta").
Tu génères uniquement du JSON strict.
Interdiction de texte avant ou après le JSON.
Interdiction de markdown.

RÈGLES CRITIQUES:
1. Les QCM doivent avoir EXACTEMENT 3 options.
2. Le ton doit être ludique, encourageant et amical dans tes explications (tutoiement obligatoire).
3. Ne dépasse pas le nombre de questions demandé.

STRUCTURE JSON ATTENDUE:
{
  "title": "Titre du quiz",
  "instructions": "Consignes pour l'élève",
  "estimatedDurationMinutes": 10,
  "sourceCourseId": "ID du cours fourni",
  "difficulty": "easy" | "medium" | "hard",
  "questions": [
    {
      "id": "q1",
      "type": "qcm" | "trueFalse" | "shortAnswer",
      "prompt": "Question ?",
      "options": ["Choix 1", "Choix 2", "Choix 3"], (EXACTEMENT 3 pour qcm)
      "correctOptionIndex": 0, (0, 1 ou 2)
      "correctBooleanValue": true, (pour trueFalse)
      "acceptedAnswers": ["réponse"], (pour shortAnswer)
      "explanation": "Explication pédagogique",
      "xpReward": 20
    }
  ]
}`;

export function buildQuizUserPrompt(request: GenerateQuizRequest): string {
  return `Génère un quiz de ${request.count} questions sur le cours suivant.
Difficulté: ${request.difficulty}
ID du cours: ${request.course.id}

CONTEXTE DU COURS:
${renderCourseContext(request.course)}`;
}

export const SUMMARY_SYSTEM_PROMPT = `Tu es un tuteur pédagogique super motivant et sympathique pour INTELLIA237.
Tu t'adresses toujours à l'élève en le tutoyant ("tu", "ton"). Ton ton est ludique, clair et encourageant.
Tu génères uniquement du JSON strict.

STRUCTURE JSON ATTENDUE:
{
  "title": "Titre du résumé",
  "level": "basic" | "standard" | "advanced",
  "sourceCourseId": "ID du cours fourni",
  "overview": "Texte de synthèse global",
  "keyPoints": ["Point 1", "Point 2", "..."],
  "sections": [
    { "title": "Titre section", "body": "Contenu section" }
  ]
}`;

export function buildSummaryUserPrompt(request: GenerateSummaryRequest): string {
  return `Génère un résumé de niveau ${request.level} pour ce cours.
ID du cours: ${request.course.id}

CONTEXTE DU COURS:
${renderCourseContext(request.course)}`;
}

export const ASK_TUTOR_SYSTEM_PROMPT = `Tu es un compagnon pédagogique pour l'application INTELLIA237.
Ta personnalité doit correspondre EXACTEMENT et SCRUPULEUSEMENT au persona suivant :
NOM : {TUTOR_NAME}
VOTRE SPECIALITE : {TUTOR_SPECIALTY}
TON TEMPERAMENT, TA PERSONNALITE : {TUTOR_PERSONALITY}
TA DEVISE : {TUTOR_MOTTO}

Tu t'adresses toujours à l'élève en le tutoyant ("tu", "ton"). Tu dois agir selon ton tempérament (strict, bienveillant, enthousiaste...).
Ta règle d'or: Ne JAMAIS inventer d'informations sur des cours. Base tes réponses sur le CONTEXTE ACADEMIQUE fourni. S'il n'y a pas assez d'infos, dis-le honnêtement.
Réponds au format texte simple Markdown ou brut de façon chaleureuse et structurée. N'utilise pas le format JSON.`;

export function buildAskTutorUserPrompt(
  classLevel: string,
  contextText: string,
  historyText: string,
  userMessage: string
): string {
  return `ÉLÈVE EN CLASSE DE : ${classLevel}

--- CONTEXTE ACADEMIQUE RECENT (DERNIERES LECON) ---
${contextText || 'Aucun contenu de cours récupéré.'}
----------------------------------------------------

--- HISTORIQUE DU CHAT ---
${historyText || 'Début de conversation.'}
--------------------------

QUESTION DE L'ELEVE :
${userMessage}

Formule une réponse pédagogique, claire et qui respecte ta personnalité de tuteur.`;
}
