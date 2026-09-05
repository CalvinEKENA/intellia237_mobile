import { describe, expect, it } from "vitest";

import { classLevelReadAliases } from "../services/quizContentStore";

describe("canonical class-level storage contract", () => {
  it("keeps Premiere canonical while accepting the production legacy alias", () => {
    expect(classLevelReadAliases("Premiere")).toEqual(["Premiere", "Première"]);
    expect(classLevelReadAliases("Première")).toEqual(["Premiere", "Première"]);
  });

  it("does not rewrite unrelated stable class identifiers", () => {
    expect(classLevelReadAliases("Terminale")).toEqual(["Terminale"]);
    expect(classLevelReadAliases("3eme")).toEqual(["3eme"]);
  });
});
