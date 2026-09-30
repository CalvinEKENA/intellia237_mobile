import { readFileSync } from "node:fs";
import { join } from "node:path";
import { describe, expect, it } from "vitest";

import { generateLinkCode, normalizeLinkCode } from "../services/childLinkCallable";

/**
 * Les codes qui donnent un droit (liaison parent, accès élève) sont tirés par
 * un générateur cryptographique. Le code de liaison parent (8 symboles) et le
 * code d'accès élève (12 symboles, HMAC) sont deux secrets distincts.
 */
describe("sensitive code generation", () => {
  it("never draws a sensitive code with Math.random", () => {
    for (const file of ["childLinkCallable.ts", "studentAccessCode.ts"]) {
      const source = readFileSync(join(__dirname, "..", "services", file), "utf8");
      expect(source, file).not.toMatch(/Math\.random/);
    }
  });

  it("keeps the visible parent link code format", () => {
    const alphabet = /^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]{8}$/;
    const codes = new Set<string>();
    for (let index = 0; index < 200; index++) {
      const code = generateLinkCode();
      expect(code).toMatch(alphabet);
      codes.add(code);
    }
    // 31^8 possibilités : 200 tirages CSPRNG ne se répètent pas.
    expect(codes.size).toBe(200);
    expect(normalizeLinkCode(" abcd-efgh ")).toBe("ABCDEFGH");
  });
});
