import { describe, expect, it } from "vitest";
import { Timestamp } from "firebase-admin/firestore";
import { assertConvertibleTeacher, decodeMigrationSnapshot, encodeMigrationSnapshot, requireTeacherConversion } from "../services/studentRoleMigration";

const user = { role: "teacher", accountStatus: "pending_validation", roles: [] };
const teacher = { workload: { activeClasses: 0, activeStudents: 0 }, subjects: ["Anglais"] };

describe("explicit teacher to student migration", () => {
  it.each([
    { confirm: false, apply: true }, { confirm: true, apply: true },
    { convertRole: "teacher:student", confirm: false, apply: true },
    { convertRole: "admin:student", confirm: true, apply: true },
  ])("rejects missing or incompatible authorization %j", (options) => {
    expect(() => requireTeacherConversion(options)).toThrow();
  });
  it("accepts the exact explicit flags, including a read-only preflight", () => {
    expect(() => requireTeacherConversion({ convertRole: "teacher:student", confirm: true, apply: false })).not.toThrow();
  });
  it("accepts only a teacher without real activity", () => {
    expect(() => assertConvertibleTeacher(user, teacher, {})).not.toThrow();
    expect(() => assertConvertibleTeacher(user, teacher, { teacher: true, role: "teacher", roles: ["teacher"] })).not.toThrow();
  });
  it.each([
    { ...user, role: "admin" }, { ...user, roles: ["parent"] }, { ...user, roles: "teacher" },
    { ...user, establishmentId: "school" }, { ...user, accountStatus: "suspended" }, { ...user, isSuperAdmin: true },
  ])("refuses other rights or administrative constraints %j", (value) => {
    expect(() => assertConvertibleTeacher(value, teacher, {})).toThrow();
  });
  it.each([
    { ...teacher, archived: true }, { ...teacher, establishmentId: "school" },
    { ...teacher, workload: { activeStudents: 1 } }, { ...teacher, analytics: {} },
  ])("refuses real or already archived teacher activity %j", (value) => {
    expect(() => assertConvertibleTeacher(user, value, {})).toThrow();
  });
  it.each([{ admin: true }, { isSuperAdmin: true }, { roles: ["teacher", "parent"] }, { entitlement: "premium" }, { teacher: "yes" }])("refuses unknown claims %j", (claims) => {
    expect(() => assertConvertibleTeacher(user, teacher, claims)).toThrow();
  });
  it("backs up timestamps losslessly, without Auth credentials", () => {
    const document = { createdAt: new Timestamp(12345, 123456789), roles: [], nested: { archived: false } };
    expect(decodeMigrationSnapshot(JSON.parse(JSON.stringify(encodeMigrationSnapshot(document))))).toEqual(document);
    expect(() => encodeMigrationSnapshot({ passwordHash: "forbidden" })).toThrow();
    expect(() => encodeMigrationSnapshot({ nested: { refreshToken: "forbidden" } })).toThrow();
    expect(() => encodeMigrationSnapshot({ createdAt: new Date() })).toThrow();
  });
});
