import { describe, expect, it } from "vitest";
import {
  manageEstablishmentInput,
  requireSuperAdmin,
  createManageEstablishmentHandler,
  type EstablishmentManagementStore,
} from "../services/establishmentManagementCallable";

describe("establishment management callable", () => {
  it("validates creation payload schema", () => {
    const valid = {
      action: "create",
      id: "lycee-bilingue-deido",
      name: "Lycée Bilingue de Deido",
      code: "LBD-237",
      city: "Douala",
      region: "Littoral",
      address: "Rue de Deido",
      status: "approved",
    };
    expect(() => manageEstablishmentInput.parse(valid)).not.toThrow();
  });

  it("validates updateStatus payload schema", () => {
    const valid = {
      action: "updateStatus",
      establishmentId: "lycee-general-yaounde",
      status: "suspended",
      reason: "Audit financier en cours",
    };
    expect(() => manageEstablishmentInput.parse(valid)).not.toThrow();
  });

  it("rejects invalid status or short reason", () => {
    expect(() =>
      manageEstablishmentInput.parse({
        action: "updateStatus",
        establishmentId: "lycee-a",
        status: "unknown_status",
        reason: "OK",
      }),
    ).toThrow();
  });

  it("enforces superAdmin role check", () => {
    expect(() => requireSuperAdmin({ role: "superAdmin", accountStatus: "active" })).not.toThrow();
    expect(() => requireSuperAdmin({ role: "super_admin", accountStatus: "active" })).not.toThrow();
    expect(() => requireSuperAdmin({ role: "admin", accountStatus: "active" })).toThrow();
    expect(() => requireSuperAdmin({ role: "teacher", accountStatus: "active" })).toThrow();
    expect(() => requireSuperAdmin({ role: "superAdmin", accountStatus: "suspended" })).toThrow();
    expect(() => requireSuperAdmin(undefined)).toThrow();
  });

  it("rejects unauthenticated callable requests", async () => {
    let called = false;
    const store = {
      execute: async () => {
        called = true;
        return { establishmentId: "e1", status: "approved" };
      },
    } as unknown as EstablishmentManagementStore;

    const handler = createManageEstablishmentHandler(store);
    await expect(handler({ data: {} } as never)).rejects.toMatchObject({
      code: "unauthenticated",
    });
    expect(called).toBe(false);
  });
});
