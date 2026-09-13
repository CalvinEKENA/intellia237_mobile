import { describe, expect, it } from "vitest";
import { audienceAllows, contentAudienceSchema, effectiveAudience } from "../services/contentAudience";

const user = { role: "student", establishmentId: "school-x", accountStatus: "active" };
const profile = (classLevel: string, series = "", educationType = "general") => ({ classLevel, series, preferences: { educationType } });
const policy = (clause: object) => ({ audience: contentAudienceSchema.parse({ version: 1, clauses: [clause] }) });
describe("generic content audience", () => {
  it.each([
    ["6eme", "", "general", { educationSystems: ["francophone"], classLevels: ["6eme"] }, true],
    ["Form1", "", "general", { educationSystems: ["anglophone"] }, true],
    ["Form1", "", "general", { educationSystems: ["francophone"] }, false],
    ["Terminale", "C", "general", { classLevels: ["Terminale"], series: ["C", "D"] }, true],
    ["Terminale", "D", "general", { classLevels: ["Terminale"], series: ["C", "D"] }, true],
    ["Terminale", "A", "general", { classLevels: ["Terminale"], series: ["C", "D"] }, false],
    ["Terminale", "TI", "general", { classLevels: ["Terminale"], series: ["C", "D"] }, false],
    ["Premiere", "C", "general", { classLevels: ["Terminale"], series: ["C", "D"] }, false],
    ["Terminale", "", "technical", { educationTypes: ["technical"] }, true],
    ["Terminale", "", "general", { educationTypes: ["technical"] }, false],
    ["UpperSixth", "", "technical", {}, true],
    ["6eme", "", "general", {}, true],
  ])("%s %s %s matches %j = %s", (level, series, type, clause, expected) => {
    expect(audienceAllows(policy(clause), user, profile(level, series, type))).toBe(expected);
  });
  it("does not cross establishments or fall back from invalid contracts", () => {
    expect(audienceAllows({ ...policy({}), scope: { type: "establishment", establishmentId: "school-y" } }, user, profile("6eme"))).toBe(false);
    expect(audienceAllows({ audience: { version: 9 } }, user, profile("6eme"))).toBe(false);
    expect(audienceAllows(policy({}), { ...user, accountStatus: "suspended" }, profile("6eme"))).toBe(false);
  });
  it("adapts legacy fields without widening the audience", () => {
    const legacy = { classLevels: ["Première"], series: ["A"], scope: { type: "global" } };
    expect(audienceAllows(legacy, user, profile("Premiere", "A"))).toBe(true);
    expect(audienceAllows(legacy, user, profile("Premiere", "D"))).toBe(false);
    expect(effectiveAudience({}, { allowedSeries: ["A"] }, "Premiere").clauses[0].series).toEqual(["A"]);
  });
  it("supports unions without creating a cross product", () => {
    const audience = { version: 1, clauses: [{ classLevels: ["6eme"] }, { classLevels: ["Form1"], educationTypes: ["technical"] }] };
    expect(audienceAllows({ audience }, user, profile("Form1", "", "general"))).toBe(false);
    expect(audienceAllows({ audience }, user, profile("Form1", "", "technical"))).toBe(true);
  });
});
