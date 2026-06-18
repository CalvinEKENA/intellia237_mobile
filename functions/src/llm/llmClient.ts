import axios from "axios";
import { getEnv } from "../config/env";

export async function generateStructuredContent<T>(params: {
  system: string;
  prompt: string;
  schema: any;
}): Promise<T> {
  const env = getEnv();

  // On utilise l'URL complète pour éviter les surprises des SDK
  const url = `${env.GLM_BASE_URL}/chat/completions`;

  console.log(`[LLM] Appel vers ${url}`);
  console.log(`[LLM] Modèle : ${env.GLM_MODEL}`);
  console.log(`[LLM] Clé API chargée (longueur) : ${env.GLM_API_KEY?.length || 0}`);
  if (env.GLM_API_KEY) {
      console.log(`[LLM] Debug Clé : ${env.GLM_API_KEY.substring(0, 4)}...${env.GLM_API_KEY.substring(env.GLM_API_KEY.length - 4)}`);
  }

  try {
    const response = await axios.post(
      url,
      {
        model: env.GLM_MODEL,
        messages: [
          { role: "system", content: params.system },
          { role: "user", content: params.prompt },
        ],
        response_format: { type: "json_object" },
      },
      {
        headers: {
          "Authorization": `Bearer ${env.GLM_API_KEY?.trim()}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
        timeout: env.LLM_SERVICE_TIMEOUT_MS,
      }
    );

    const content = response.data.choices[0].message.content;
    if (!content) {
      throw new Error("Empty response from LLM");
    }

    const parsed = JSON.parse(content);
    return params.schema.parse(parsed);
  } catch (error: any) {
    if (axios.isAxiosError(error)) {
      console.error("[LLM] Axios Error:", error.response?.status, error.response?.data);
      throw new Error(`LLM API Error: ${error.response?.status} - ${JSON.stringify(error.response?.data)}`);
    }
    throw error;
  }
}

export async function generateText(params: {
  system: string;
  prompt: string;
}): Promise<string> {
  const env = getEnv();
  const url = `${env.GLM_BASE_URL}/chat/completions`;

  try {
    const response = await axios.post(
      url,
      {
        model: env.GLM_MODEL,
        messages: [
          { role: "system", content: params.system },
          { role: "user", content: params.prompt },
        ],
      },
      {
        headers: {
          "Authorization": `Bearer ${env.GLM_API_KEY?.trim()}`,
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        timeout: env.LLM_SERVICE_TIMEOUT_MS,
      }
    );

    const content = response.data.choices[0]?.message?.content;
    if (!content) {
      throw new Error("Empty response from LLM");
    }
    return content;
  } catch (error: any) {
    if (axios.isAxiosError(error)) {
      console.error("[LLM] Axios Error:", error.response?.status, error.response?.data);
      throw new Error(`LLM API Error: ${error.response?.status} - ${JSON.stringify(error.response?.data)}`);
    }
    throw error;
  }
}
