import { describe, expect, it } from "vitest";

import {
  createLinkChildByCodeHandler,
  createEnsureStudentLinkCodeHandler,
  createRotateStudentLinkCodeHandler,
  generateLinkCode,
  linkRateLimit,
  normalizeLinkCode,
  type ChildLinkStore,
  type StudentSummary,
} from "../services/childLinkCallable";

class MemoryChildLinkStore implements ChildLinkStore {
  roles = new Map<string, string>();
  codes = new Map<string, string>(); // code -> studentId
  students = new Map<string, StudentSummary>();
  links: { parentId: string; studentId: string }[] = [];
  studentCodes = new Map<string, string>(); // studentId -> code
  failures = new Map<string, number>();
  private _codeSeq = 0;

  async readRole(uid: string) {
    return this.roles.get(uid);
  }

  async isRateLimited(parentId: string) {
    return (this.failures.get(parentId) ?? 0) >= linkRateLimit.maxFailures;
  }

  async recordFailedAttempt(parentId: string) {
    this.failures.set(parentId, (this.failures.get(parentId) ?? 0) + 1);
  }

  async resetAttempts(parentId: string) {
    this.failures.delete(parentId);
  }

  async resolveStudentByCode(code: string) {
    return this.codes.get(code) ?? null;
  }

  async readStudentSummary(studentId: string) {
    return this.students.get(studentId) ?? null;
  }

  async upsertApprovedLink(params: { parentId: string; studentId: string }) {
    const already = this.links.some(
      (l) => l.parentId === params.parentId && l.studentId === params.studentId,
    );
    if (!already) this.links.push(params);
    return { alreadyLinked: already };
  }

  async ensureLinkCode(studentId: string) {
    const existing = this.studentCodes.get(studentId);
    if (existing) return existing;
    return this._issue(studentId, null);
  }

  async rotateLinkCode(studentId: string) {
    const previous = this.studentCodes.get(studentId) ?? null;
    return this._issue(studentId, previous);
  }

  private _issue(studentId: string, previous: string | null): string {
    if (previous) this.codes.delete(previous);
    const code = `CODE${++this._codeSeq}`;
    this.studentCodes.set(studentId, code);
    this.codes.set(code, studentId);
    return code;
  }
}

function seededStore(): MemoryChildLinkStore {
  const store = new MemoryChildLinkStore();
  store.roles.set("parent-1", "parent");
  store.roles.set("parent-2", "parent");
  store.roles.set("student-1", "student");
  store.roles.set("teacher-1", "teacher");
  store.codes.set("ABCDEFGH", "student-1");
  store.studentCodes.set("student-1", "ABCDEFGH");
  store.students.set("student-1", {
    studentId: "student-1",
    firstName: "Awa",
    classLevel: "Terminale",
  });
  return store;
}

describe("linkChildByCode", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createLinkChildByCodeHandler(seededStore());
    await expect(
      handler({ data: { code: "ABCDEFGH" } } as never),
    ).rejects.toMatchObject({ code: "unauthenticated" });
  });

  it("rejects non-parent callers", async () => {
    const handler = createLinkChildByCodeHandler(seededStore());
    await expect(
      handler({
        auth: { uid: "student-1" },
        data: { code: "ABCDEFGH" },
      } as never),
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("links a valid code and returns the child summary (approved)", async () => {
    const store = seededStore();
    const handler = createLinkChildByCodeHandler(store);
    await expect(
      handler({
        auth: { uid: "parent-1" },
        data: { code: "abcd-efgh" },
      } as never),
    ).resolves.toEqual({
      studentId: "student-1",
      firstName: "Awa",
      classLevel: "Terminale",
      alreadyLinked: false,
    });
    expect(store.links).toEqual([
      { parentId: "parent-1", studentId: "student-1" },
    ]);
  });

  it("is idempotent: a duplicate link reports alreadyLinked", async () => {
    const store = seededStore();
    const handler = createLinkChildByCodeHandler(store);
    await handler({
      auth: { uid: "parent-1" },
      data: { code: "ABCDEFGH" },
    } as never);
    const second = await handler({
      auth: { uid: "parent-1" },
      data: { code: "ABCDEFGH" },
    } as never);
    expect(second.alreadyLinked).toBe(true);
    expect(store.links).toHaveLength(1);
  });

  it("rejects an unknown code with not-found", async () => {
    const handler = createLinkChildByCodeHandler(seededStore());
    await expect(
      handler({
        auth: { uid: "parent-1" },
        data: { code: "ZZZZZZZZ" },
      } as never),
    ).rejects.toMatchObject({ code: "not-found" });
  });

  it("rejects a missing/empty code with invalid-argument", async () => {
    const handler = createLinkChildByCodeHandler(seededStore());
    await expect(
      handler({ auth: { uid: "parent-1" }, data: {} } as never),
    ).rejects.toMatchObject({ code: "invalid-argument" });
  });

  it("lets a different parent link the same child (shared code)", async () => {
    const store = seededStore();
    const handler = createLinkChildByCodeHandler(store);
    await handler({
      auth: { uid: "parent-1" },
      data: { code: "ABCDEFGH" },
    } as never);
    await handler({
      auth: { uid: "parent-2" },
      data: { code: "ABCDEFGH" },
    } as never);
    expect(store.links).toEqual([
      { parentId: "parent-1", studentId: "student-1" },
      { parentId: "parent-2", studentId: "student-1" },
    ]);
  });

  describe("anti-bruteforce", () => {
    it("blocks after too many failed attempts, with a generic error", async () => {
      const store = seededStore();
      const handler = createLinkChildByCodeHandler(store);
      // maxFailures échecs consécutifs (codes inconnus).
      for (let i = 0; i < linkRateLimit.maxFailures; i++) {
        await expect(
          handler({
            auth: { uid: "parent-1" },
            data: { code: `MISS${i}` },
          } as never),
        ).rejects.toMatchObject({ code: "not-found" });
      }
      // La tentative suivante — même avec un VRAI code — est refusée sans
      // révéler l'existence du code (résistance à l'énumération).
      await expect(
        handler({
          auth: { uid: "parent-1" },
          data: { code: "ABCDEFGH" },
        } as never),
      ).rejects.toMatchObject({ code: "resource-exhausted" });
    });

    it("a successful link resets the failure counter", async () => {
      const store = seededStore();
      const handler = createLinkChildByCodeHandler(store);
      await expect(
        handler({
          auth: { uid: "parent-1" },
          data: { code: "NOPE0000" },
        } as never),
      ).rejects.toMatchObject({ code: "not-found" });
      expect(store.failures.get("parent-1")).toBe(1);
      await handler({
        auth: { uid: "parent-1" },
        data: { code: "ABCDEFGH" },
      } as never);
      expect(store.failures.has("parent-1")).toBe(false);
    });
  });
});

describe("ensureStudentLinkCode", () => {
  it("rejects unauthenticated callers", async () => {
    const handler = createEnsureStudentLinkCodeHandler(seededStore());
    await expect(handler({ data: {} } as never)).rejects.toMatchObject({
      code: "unauthenticated",
    });
  });

  it("rejects non-student callers (a parent has no link code)", async () => {
    const handler = createEnsureStudentLinkCodeHandler(seededStore());
    await expect(
      handler({ auth: { uid: "parent-1" }, data: {} } as never),
    ).rejects.toMatchObject({ code: "permission-denied" });
  });

  it("returns a stable code for the student (idempotent)", async () => {
    const store = seededStore();
    const handler = createEnsureStudentLinkCodeHandler(store);
    const first = await handler({
      auth: { uid: "student-1" },
      data: {},
    } as never);
    const second = await handler({
      auth: { uid: "student-1" },
      data: {},
    } as never);
    expect(first.code).toBe(second.code);
  });
});

describe("rotateStudentLinkCode", () => {
  it("issues a new code and invalidates the previous one immediately", async () => {
    const store = seededStore();
    const rotate = createRotateStudentLinkCodeHandler(store);
    const link = createLinkChildByCodeHandler(store);

    const rotated = await rotate({
      auth: { uid: "student-1" },
      data: {},
    } as never);
    expect(rotated.code).not.toBe("ABCDEFGH");

    // L'ancien code ne résout plus rien → not-found.
    await expect(
      link({ auth: { uid: "parent-1" }, data: { code: "ABCDEFGH" } } as never),
    ).rejects.toMatchObject({ code: "not-found" });

    // Le nouveau code fonctionne.
    await expect(
      link({
        auth: { uid: "parent-1" },
        data: { code: rotated.code },
      } as never),
    ).resolves.toMatchObject({ studentId: "student-1" });
  });

  it("rejects non-student callers", async () => {
    const handler = createRotateStudentLinkCodeHandler(seededStore());
    await expect(
      handler({ auth: { uid: "parent-1" }, data: {} } as never),
    ).rejects.toMatchObject({ code: "permission-denied" });
  });
});

describe("code helpers", () => {
  it("normalizes case, spaces and dashes", () => {
    expect(normalizeLinkCode("  ab cd-ef gh ")).toBe("ABCDEFGH");
    expect(normalizeLinkCode(42)).toBe("");
  });

  it("generates codes from the unambiguous alphabet only", () => {
    const code = generateLinkCode(() => 0);
    expect(code).toHaveLength(8);
    expect(code).toMatch(/^[ABCDEFGHJKMNPQRSTUVWXYZ23456789]+$/);
  });
});
