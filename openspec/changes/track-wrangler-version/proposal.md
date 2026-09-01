## Why

Wrangler's version is pinned in a raw `RUN bun add -g wrangler@4.120.0` line
in the Dockerfile, outside any manifest Dependabot reads. `renovate.json` once
covered this gap with a custom regex manager, but Renovate's `autodiscover`
never reaches a repo whose primary remote is `github.com` — it never actually
ran, and was removed in #28. Since then nothing bumps wrangler at all, and a
security-relevant release can sit unnoticed indefinitely. Tracked in #27.

## What Changes

- Move the pinned wrangler version into `package.json`'s `devDependencies`,
  where Dependabot's existing `bun` ecosystem entry already watches and bumps
  every other pinned version in this repo.
- The Dockerfile's build stage reads that same version at build time instead
  of hardcoding it a second time, so there is exactly one place to update and
  Dependabot's bump is what changes the built image.
- Exclude `wrangler` from the `bun-dependencies` Dependabot group: it is the
  one bun-ecosystem dependency that actually ships in the image, so it gets
  its own pull request rather than riding along with a dev-tooling bump like
  biome or prettier.
- Update CONTRIBUTING.md's Pinning section, which still describes the old
  Renovate-based mechanism.

## Capabilities

### New Capabilities

- `wrangler-version-tracking`: the Dockerfile's wrangler version is sourced
  from a manifest a dependency bot actively watches, so a new release opens a
  pull request without manual intervention.

### Modified Capabilities

(none)

## Impact

- `package.json`: adds `wrangler` to `devDependencies`; `bun.lock` gains its
  resolution.
- `Dockerfile`: build stage copies `package.json` and reads the pinned
  version from it instead of hardcoding it in the `bun add -g` line.
- `.github/dependabot.yml`: `bun-dependencies` group gets an
  `exclude-patterns` entry for `wrangler`.
- `CONTRIBUTING.md`: Pinning section describes the new mechanism.
- No change to what `wrangler` version ships today — this only changes how
  future bumps happen.
