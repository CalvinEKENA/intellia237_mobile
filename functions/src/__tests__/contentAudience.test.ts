import { describe, expect, it } from "vitest";
import { audienceAllows, contentAudienceSchema, effectiveAudience } from "../services/contentAudience";
import { declaresClass } from "../services/learningCatalogCallable";

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
  it("binds a clause without class levels to the document's own class", () => {
    const open = policy({ educationSystems: ["francophone"] });
    expect(audienceAllows(open, user, profile("Terminale", "D"), "6eme")).toBe(false);
    expect(audienceAllows(open, user, profile("6eme"), "6eme")).toBe(true);
    expect(audienceAllows(policy({ classLevels: ["Terminale"], series: ["C", "D"] }), user, profile("Terminale", "D"), "Terminale")).toBe(true);
    expect(audienceAllows(policy({ classLevels: ["Terminale"], series: ["D"] }), user, profile("Terminale", "C"), "Terminale")).toBe(false);
  });
});


describe("catalog class declaration", () => {
  it("requires an explicit class, never a location alone", () => {
    expect(declaresClass({ title: "Module 1" })).toBe(false);
    expect(declaresClass({ classLevel: "6eme" })).toBe(true);
    expect(declaresClass({ classLevels: ["Terminale"] })).toBe(true);
    expect(declaresClass({ audience: { version: 1, clauses: [{ classLevels: [] }] } })).toBe(false);
    expect(declaresClass({ audience: { version: 1, clauses: [{ classLevels: ["Terminale"], series: ["D"] }] } })).toBe(true);
  });
});
