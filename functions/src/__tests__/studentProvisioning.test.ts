import { describe, expect, it } from "vitest";
import { planStudentProvision } from "../services/studentProvisioning";

const input = { email: "student@yahoo.fr", role: "student", classLevel: "terminale", series: "D" };
describe("safe student provisioning", () => {
  it("uses the official academic fields without inventing identity or consents", () => {
    const plan = planStudentProvision(input, "uid", {});
    expect(plan.user).toMatchObject({ role: "student", classLevel: "Terminale", series: "D", profileCompleted: false });
    expect(plan.profile).toMatchObject({ points: 0, level: 1 });
    expect(plan.profile).not.toHaveProperty("consents");
    expect(plan.user).not.toHaveProperty("password");
  });
  it("is a no-op on replay and preserves progress and identity", () => {
    const first = planStudentProvision(input, "uid", {});
    const again = planStudentProvision(input, "uid", { user: { ...first.user, firstName: "Test", profileCompleted: true }, profile: { ...first.profile, points: 789 } });
    expect(again.user).toEqual({}); expect(again.profile).toEqual({});
  });
  it.each(["parent", "teacher", "admin", "superAdmin"])("refuses an existing %s", (role) => {
    expect(() => planStudentProvision(input, "uid", { user: { role } })).toThrow();
  });
  it.each([{ claims: { admin: true } }, { claims: { role: "teacher" } }, { claims: { roles: ["parent"] } }, { adultProfile: true }, { disabled: true }, { user: { role: "student", classLevel: "Troisième" } }, { profile: { series: "C" } }, { profile: { uid: "another" } }])("refuses incompatible state %j", (state) => {
    expect(() => planStudentProvision(input, "uid", state)).toThrow();
  });
  it.each([
    { claims: { isSuperAdmin: true } },
    { profile: { preferences: { educationalSubsystem: "anglophone" } } },
    { profile: { preferences: { educationType: "technical" } } },
    { profile: { preferences: { academicLevelId: "fr_general_premiere" } } },
    { profile: { preferences: { streamOrSpeciality: "C" } } },
  ])("refuses incompatible claims or academic preferences %j", (state) => {
    expect(() => planStudentProvision(input, "uid", state)).toThrow();
  });
  it("cannot provision an adult role from CLI input", () => {
    expect(() => planStudentProvision({ ...input, role: "admin" }, "uid", {})).toThrow();
  });
});
