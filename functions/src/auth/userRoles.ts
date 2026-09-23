/**
 * Rôles d'un compte, lus comme les règles Firestore les lisent.
 *
 * Registre de décisions (refonte Auth V2, P1-2 de la revue de 7ea5cf0) :
 * les règles acceptaient le champ additif `roles: string[]` (une personne
 * peut être parent ET enseignante), mais le serveur ne lisait que le champ
 * historique `role`. Un compte enseignant + parent voyait son espace parent
 * s'ouvrir, puis chaque callable parent le refusait. Tout contrôle de rôle
 * du serveur passe désormais par ce module.
 *
 * Modèle :
 * - `role` (historique) reste le rôle principal, lu par les anciennes
 *   versions de l'application ; il est toujours présent.
 * - `roles` (additif) liste TOUS les espaces du compte, `role` compris.
 *   Seul le serveur l'écrit (règles : absent des clés modifiables par le
 *   client), via `manageUserRoles` réservé à la super-administration.
 * - L'élève est exclusif : un compte élève n'a pas d'autre espace, et aucun
 *   autre compte ne devient élève par `roles`.
 * - La super-administration ne s'accorde jamais par `roles` : elle ne se lit
 *   que dans `role`.
 */

export const combinableRoles = ["parent", "teacher", "admin"] as const;
export type CombinableRole = (typeof combinableRoles)[number];
export type AccountRole = "student" | CombinableRole;

const superAdminRoleNames = new Set(["superAdmin", "super_admin"]);

function text(value: unknown): string {
  return typeof value === "string" ? value.trim() : "";
}

function recordOf(userData: unknown): Record<string, unknown> {
  return userData !== null && typeof userData === "object"
    ? (userData as Record<string, unknown>)
    : {};
}

/** Rôle principal historique, tel qu'écrit dans `role`. */
export function primaryRole(userData: unknown): string {
  return text(recordOf(userData).role);
}

/** Super-administration : seulement par le rôle principal. */
export function isSuperAdminUser(userData: unknown): boolean {
  return superAdminRoleNames.has(primaryRole(userData));
}

/**
 * Tous les espaces du compte : l'union de `role` et de `roles`. Un compte
 * élève n'en a qu'un ; `superAdmin` n'est jamais lu dans `roles`.
 */
export function resolveUserRoles(userData: unknown): Set<string> {
  const data = recordOf(userData);
  const primary = primaryRole(data);
  const roles = new Set<string>();
  if (primary) roles.add(superAdminRoleNames.has(primary) ? "superAdmin" : primary);
  if (primary === "student") return roles;
  const additive = data.roles;
  if (Array.isArray(additive)) {
    for (const value of additive) {
      const role = text(value);
      if ((combinableRoles as readonly string[]).includes(role)) roles.add(role);
    }
  }
  return roles;
}

/** Le compte dispose-t-il de l'espace [role] ? */
export function hasUserRole(userData: unknown, role: AccountRole | "superAdmin"): boolean {
  if (role === "superAdmin") return isSuperAdminUser(userData);
  return resolveUserRoles(userData).has(role);
}

/** Au moins un des espaces [roles]. */
export function hasAnyUserRole(
  userData: unknown,
  roles: ReadonlyArray<AccountRole | "superAdmin">,
): boolean {
  return roles.some((role) => hasUserRole(userData, role));
}

/**
 * Écriture cohérente des deux champs après un ajout ou un retrait d'espace.
 *
 * Politique de révocation :
 * - retirer un espace qui n'est pas le principal ne touche que `roles` ;
 * - retirer l'espace principal fait du premier espace restant le nouveau
 *   `role` (ordre : admin, teacher, parent), pour que les anciennes versions
 *   n'ouvrent jamais l'espace retiré ;
 * - retirer le dernier espace est refusé : on suspend un compte, on ne le
 *   laisse pas sans espace ;
 * - `roles` n'est écrit que s'il reste plusieurs espaces ; sinon il est
 *   supprimé, et le compte redevient un compte à rôle unique ordinaire.
 */
export type RoleChange =
  | { ok: true; role: CombinableRole; roles: CombinableRole[] | null }
  | { ok: false; reason: "student-exclusive" | "super-admin" | "last-role" | "unknown-role" | "unchanged" };

const revocationOrder: CombinableRole[] = ["admin", "teacher", "parent"];

export function planRoleChange(
  userData: unknown,
  change: { action: "grant" | "revoke"; role: string },
): RoleChange {
  const primary = primaryRole(userData);
  if (superAdminRoleNames.has(primary)) return { ok: false, reason: "super-admin" };
  if (primary === "student") return { ok: false, reason: "student-exclusive" };
  if (!(combinableRoles as readonly string[]).includes(change.role)) {
    return { ok: false, reason: change.role === "student" ? "student-exclusive" : "unknown-role" };
  }
  const role = change.role as CombinableRole;
  const current = [...resolveUserRoles(userData)].filter((value): value is CombinableRole =>
    (combinableRoles as readonly string[]).includes(value),
  );
  const next = new Set(current);
  if (change.action === "grant") {
    if (next.has(role)) return { ok: false, reason: "unchanged" };
    next.add(role);
  } else {
    if (!next.has(role)) return { ok: false, reason: "unchanged" };
    next.delete(role);
    if (next.size === 0) return { ok: false, reason: "last-role" };
  }
  const ordered = revocationOrder.filter((value) => next.has(value));
  const nextPrimary = next.has(primary as CombinableRole)
    ? (primary as CombinableRole)
    : ordered[0];
  return {
    ok: true,
    role: nextPrimary,
    roles: ordered.length > 1
      ? [nextPrimary, ...ordered.filter((value) => value !== nextPrimary)]
      : null,
  };
}
