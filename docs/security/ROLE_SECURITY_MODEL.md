# Role Security Model

## Current Rule Boundary

Public client account creation can bootstrap only these roles:

- `student`
- `parent`

The following roles are not public self-assignment roles:

- `teacher`
- `admin`
- `superAdmin`

`role` is immutable from client updates. Owner updates on `users/{uid}` are limited to safe profile/display fields.

## Public Bootstrap

Students may create:

- `users/{uid}` with role `student`.
- `student_profiles/{uid}` with `xp = 0` and `level = 1`.

Parents may create:

- `users/{uid}` with role `parent`.
- `parent_profiles/{uid}` through the existing parent registration flow.

## Blocked Public Paths

These client-side flows are intentionally blocked by rules until a server review workflow exists:

- Direct teacher role creation from the teacher registration screen.
- Direct admin role creation from the admin registration screen.
- Owner updates that change `role`, `establishmentId`, XP, entitlement, subscription, approval, or academic fields.

## Staff Provisioning Target

The target onboarding flow is:

1. Public user submits a staff request into a non-privileged request collection.
2. A superAdmin or trusted backend validates identity and establishment.
3. A server-side privileged workflow writes `users/{uid}.role`, establishment assignment, approval state, and the matching staff profile.
4. Audit metadata records who approved the role and when.

This Phase 2A change does not implement the staff request workflow; it closes the unsafe self-assignment path.
