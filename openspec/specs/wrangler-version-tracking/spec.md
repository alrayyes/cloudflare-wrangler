# wrangler-version-tracking Specification

## Purpose

Keeps the wrangler CLI version baked into this image current by making it
visible to Dependabot, instead of a version pinned only inside a Dockerfile
`RUN` line that no tooling watches.

## Requirements

### Requirement: Wrangler's pinned version is Dependabot-visible

The wrangler version SHALL be declared as an exact-pinned entry in
`package.json`'s `devDependencies`, where Dependabot's existing `bun`
ecosystem configuration already watches for new releases.

#### Scenario: A new wrangler release is published

- **WHEN** a new wrangler version is published to npm
- **THEN** Dependabot opens a pull request bumping the `wrangler` entry in
  `package.json`'s `devDependencies` on its next scheduled run

### Requirement: The built image's wrangler version matches the pinned manifest entry

The Dockerfile SHALL install the exact wrangler version declared in
`package.json`'s `devDependencies`, read at build time, rather than a version
hardcoded a second time in the Dockerfile itself.

#### Scenario: Building the image after a version bump

- **WHEN** `package.json`'s `wrangler` `devDependencies` entry changes and the
  image is rebuilt
- **THEN** the resulting image carries that same wrangler version, with no
  other file requiring a matching edit

### Requirement: A wrangler version bump gets its own pull request

Dependabot's grouping for the `bun` ecosystem SHALL exclude `wrangler`, so a
wrangler bump is not folded into the same pull request as unrelated dev
tooling bumps (biome, prettier, and the like).

#### Scenario: Wrangler and a dev-tooling dependency both have updates available

- **WHEN** Dependabot's scheduled run finds an update for `wrangler` and,
  separately, for a dev-tooling dependency such as `@biomejs/biome`
- **THEN** Dependabot opens two separate pull requests, one for `wrangler`
  and one for the grouped dev-tooling bump
