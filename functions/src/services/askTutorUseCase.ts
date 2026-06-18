import * as admin from "firebase-admin";
import { generateText } from "../llm/llmClient";
import { ASK_TUTOR_SYSTEM_PROMPT, buildAskTutorUserPrompt } from "../llm/prompts";
import { AskTutorCallableInput } from "../utils/validation";

export class AskTutorUseCase {
  async execute(params: {
    userId: string;
    traceId: string;
    input: AskTutorCallableInput;
  }): Promise<{ text: string }> {
    const db = admin.firestore();
    const { classLevel, tutor, history, userMessage } = params.input;

    // Fetch up to 5 recently updated/ordered lessons for this classLevel
    // To do this simply without complex group queries, we can just grab from a hardcoded subject for now,
    // or use a collectionGroup query to find lessons if we want broad context.
    let contextText = "";
    try {
      const lessonsSnap = await db
        .collectionGroup("lessons")
        .where("status", "==", "published")
        .limit(3)
        .get();

      // We should ideally filter by classLevel, but since collectionGroup matches all lessons,
      // it might pull from other classes if we don't have a classLevel field in lesson.
      // Assuming we just grab the first 3 lessons for the RAG context.
      const lessons = lessonsSnap.docs.map(d => d.data());

      const sections = lessons.map(l => {
        let text = `Titre Leçon: ${l.title || 'Sans titre'}\n`;
        const contentSections = l.contentSections || [];
        contentSections.forEach((s: any) => {
          text += `${s.title || ''}\n${s.body || ''}\n`;
        });
        return text;
      });

      contextText = sections.join("\n\n---\n\n");
      // Truncate to avoid exploding context window
      if (contextText.length > 5000) {
        contextText = contextText.substring(0, 5000) + "...";
      }
    } catch (e) {
      console.warn("Failed to fetch context for RAG", e);
    }

    const historyText = history.map(h => `${h.role}: ${h.text}`).join("\n");

    const systemPrompt = ASK_TUTOR_SYSTEM_PROMPT
      .replace("{TUTOR_NAME}", tutor.name)
      .replace("{TUTOR_SPECIALTY}", tutor.specialty)
      .replace("{TUTOR_PERSONALITY}", tutor.personality)
      .replace("{TUTOR_MOTTO}", tutor.motto);

    const userPrompt = buildAskTutorUserPrompt(
      classLevel,
      contextText,
      historyText,
      userMessage
    );

    const responseText = await generateText({
      system: systemPrompt,
      prompt: userPrompt,
    });

    return { text: responseText };
  }
}
