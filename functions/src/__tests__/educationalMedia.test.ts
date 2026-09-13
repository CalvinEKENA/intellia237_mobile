import { readFileSync } from "node:fs";
import { describe, expect, it, vi } from "vitest";
import type { Bucket } from "@google-cloud/storage";
import { inspectMp4 } from "../services/mp4Validation";
import { parseAssetPath, validateLessonMedia } from "../services/educationalMedia";

const bytes = readFileSync(new URL("../../../test/fixtures/video/synthetic-chemistry-h264-aac.mp4", import.meta.url));
const path = "educational_assets/global/Terminale/chemistry/lesson/video-unique/video.mp4";
const block = { id: "video-unique", order: 0, type: "media", mediaType: "video", storagePath: path, mimeType: "video/mp4" };
const lesson = () => ({ id: "lesson", classLevel: "Terminale", subjectId: "chemistry", scope: { type: "global" }, contentBlocks: [{ ...block }] });
function storage(options: { missing?: boolean; size?: number; mime?: string; data?: Buffer } = {}) {
  return { file: vi.fn(() => ({
    getMetadata: async () => { if (options.missing) throw new Error("404"); return [{ generation: "123", size: options.size ?? bytes.length, contentType: options.mime ?? "video/mp4" }]; },
    download: async () => [options.data ?? bytes],
  })) } as unknown as Bucket;
}
describe("canonical MP4 publication", () => {
  it("inspects a real H.264/AAC fixture and persists authoritative size and duration", async () => {
    expect(inspectMp4(bytes).durationSeconds).toBe(4);
    const source = lesson();
    const assets = await validateLessonMedia(source, storage());
    expect(assets[0]).toMatchObject({ path, size: bytes.length, generation: "123" });
    expect(source.contentBlocks[0]).toMatchObject({ fileSizeBytes: bytes.length, durationSeconds: 4 });
  });
  it.each([
    { missing: true }, { size: 0 }, { size: 150 * 1024 * 1024 + 1 },
    { mime: "video/webm" }, { mime: "text/html" }, { data: bytes.subarray(0, 64) },
  ])("rejects missing, incomplete or noncanonical media %j", async options => {
    await expect(validateLessonMedia(lesson(), storage(options))).rejects.toMatchObject({ code: "failed-precondition" });
  });
  it("rejects fake codec strings and another lesson's asset", async () => {
    expect(() => inspectMp4(Buffer.from("ftyp mp4 avc1 mp4a AAC not a movie"))).toThrow();
    await expect(validateLessonMedia({ ...lesson(), id: "other" }, storage())).rejects.toMatchObject({ code: "permission-denied" });
    expect(() => parseAssetPath("educational_assets/global/../x" )).toThrow();
  });
  it("rejects a non-H.264 sample description in the actual MP4", () => {
    const bad = Buffer.from(bytes);
    const index = bad.indexOf(Buffer.from("avc1"), bad.indexOf(Buffer.from("stsd")));
    expect(index).toBeGreaterThan(0);
    bad.write("hvc1", index, "ascii");
    expect(() => inspectMp4(bad)).toThrow();
  });
});
