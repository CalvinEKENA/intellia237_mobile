import { applicationDefault } from "firebase-admin/app";

let credential: ReturnType<typeof applicationDefault> | null = null;

export async function getVertexAccessToken(): Promise<string> {
  credential ??= applicationDefault();
  const token = await credential.getAccessToken();
  const accessToken = token.access_token?.trim();

  if (!accessToken) {
    throw new Error("Vertex AI access token is unavailable.");
  }

  return accessToken;
}
