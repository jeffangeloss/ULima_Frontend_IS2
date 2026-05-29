# ULima++ Frontend Specs

Specs in this folder describe Flutter behavior by product feature. The existing `lib/` structure stays unchanged.

## Current Context

- Backend provider is `../../ULima_Backend_IS2`.
- PostgreSQL behind the backend is the source of truth.
- `assets/data/*.json` files are disposable mocks and must not be used as final fallback.
- Every API dependency must match `docs/specs/api-contracts.md`.
- Implement only after the feature spec is approved.

Conventions:

- One feature folder per product feature.
- Spec files end with `.spec.md`.
- Each spec has YAML frontmatter with `name`, `description`, and `targets`.
- `targets` point to existing pages, controllers, services, models, mockups, or docs.
- Services must own API/data access; widgets must not call HTTP or read JSON directly.
- Add `[@test]` links only after the referenced Flutter tests exist.

Current feature folders:

- `auth`
- `academic-profile`
- `curriculum`
- `grades`
- `schedule`
- `course-detail`
- `alerts`
- `section-management`
