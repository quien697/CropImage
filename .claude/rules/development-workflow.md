# Development Workflow

> This is the CropImage projection of my personal baseline, `my-openspec-with-superpowers`
> (quien-wiki) — the source of truth for the general workflow. This doc adds only the
> project-specific rules; when the two disagree, the baseline wins on process and this doc
> wins on CropImage specifics.

How features and fixes get built in CropImage. It combines two tools:

- **OpenSpec** owns the durable artifacts: the *proposal*, the *design*, the *task
  breakdown*, and the living *specs* under `openspec/specs/`.
- **Superpowers** owns the *discipline*: brainstorming before design, test-driven
  development while implementing, and verification before claiming done.

There is **one** set of planning artifacts per change (OpenSpec's), never a parallel copy
under `docs/superpowers/`.

## The loop

1. **Brainstorm** (`superpowers:brainstorming`) — agree on the design before any artifact
   is written. Save nothing; the design goes into the OpenSpec change (step 2).
   - Changes often arrive because one app needs them. Brainstorm the general version:
     CropImage is shared by several apps, so an option shaped around one app's numbers or
     screens is a design smell.
2. **Create an OpenSpec change** (`/opsx:propose`). This produces, under
   `openspec/changes/<change-id>/`: `proposal.md`, `design.md`, the spec delta in
   `specs/<capability>/spec.md`, and `tasks.md`. **`tasks.md` is the plan**; there is no
   separate plan doc.
   - In `proposal.md`, mark anything that stops existing call sites from compiling or
     changes what `onCrop` delivers as **BREAKING**: it needs a major version. Prefer a new
     defaulted `init` parameter, which needs only a minor version.
3. **Branch** from `develop` — never work on `main` or `develop` directly.
4. **Implement each task with TDD** (`superpowers:test-driven-development`), one `tasks.md`
   item at a time, checking each off as it lands.
   - Output behavior is testable through `CropImageViewModel.crop`. Check pixel content,
     not only dimensions: `ImageRenderer` can return a correctly sized image that is blank.
   - *Per-task exception:* gestures, the mask, and layout have no unit-testable surface.
     Say so in the task and verify in a `#Preview` or the demo app on the `with-demo`
     branch, rather than writing a test that asserts nothing.
5. **Verify** (`superpowers:verification-before-completion`) — build and run the full test
   suite on an iOS simulator (commands in `CLAUDE.md`). Evidence before claims.
6. **Code review** (`/code-review`), checked against the spec delta.
7. **Finish the branch** (`superpowers:finishing-a-development-branch`) — PR into `develop`.
8. **Archive** (`/opsx:archive`) — folds the spec delta into
   `openspec/specs/<capability>/spec.md`. Fill in the capability's `Purpose` if the archive
   left it as `TBD`.
   - Archive on the feature branch, after the change's commits and before opening the PR
     in step 7, so the spec update merges into `develop` together with the code.

## Branches and releases

- `main` holds released code only. `develop` collects finished work, and every change
  reaches it through a PR from its own branch.
- To release, open a PR from `develop` into `main` and merge it, then tag the merge on
  `main` with the version (`1.1.0`, no `v` prefix) and push the tag. Apps resolve
  versions from tags, so nothing reaches them until the tag exists.
- Pick the version from the changes merged since the last tag: any **BREAKING** change
  means a major version, a new option a minor version, and fixes alone a patch version.

## When to skip OpenSpec

Skip it for trivial changes (typos, README wording, tooling, dependency bumps) and just
make the change, still with a test when there's a testable surface. If a "small" change
alters behavior described in `openspec/specs/`, such as an output size, the crop region,
or how gestures snap back, stop and open a change so the spec stays honest.

## Reconciliation rules

- **Specs describe what an app using the library can observe**: `CropImageView`,
  `CropShape`, and the image `onCrop` delivers. Internal types (`CropImageViewModel`,
  `CropGeometry`, the mask views) can change without a spec delta as long as that
  behavior stays the same.
- **Specs track code.** Any change that alters `crop-interaction` or `crop-output` must
  include a spec delta. Treat an undocumented behavior change as a spec gap in review.
- **Superpowers contributes discipline, not artifacts.**

## Tooling

- The `openspec` CLI is installed globally via npm (`which openspec` to confirm). The
  skills drive it: `openspec-propose` / `openspec-update-change` / `openspec-apply-change` /
  `openspec-sync-specs` / `openspec-archive-change` (and their `opsx:*` aliases; `apply` is
  deliberately unused, since steps 3–5 replace it). Useful directly:
  `openspec status --change <name>`, `openspec validate <name> --strict`.
- Project context for OpenSpec generation can go in `openspec/config.yaml` (`context:` and
  `rules:`). Keep it aligned with `CLAUDE.md`.
- If the CLI is missing on a new machine: `npm install -g @fission-ai/openspec`.
