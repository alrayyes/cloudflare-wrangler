## Context

The Dockerfile's build stage runs `bun add -g wrangler@4.120.0` — a version
that exists only in that one line. See proposal.md for why nothing currently
bumps it.

## Goals / Non-Goals

**Goals:**

- One place to bump wrangler's version; everything else follows from it.
- Dependabot opens the pull request; no new scheduled workflow to maintain.

**Non-Goals:**

- Tracking the `curl`/`ca-certificates` apk pins in the same Dockerfile — a
  separate gap with no Dependabot-native fix available, filed as #29.
- Changing which wrangler version ships today.

## Decisions

**Move the pin into `package.json`'s `devDependencies`, read by the
Dockerfile at build time.** Dependabot's `bun` ecosystem entry
(`.github/dependabot.yml`) already watches this manifest and already bumps
every other pinned devDependency here. Adding `wrangler` to it costs nothing
new — no additional Dependabot config, no new workflow.

Alternatives considered (from issue #27's own list):

- _A custom scheduled workflow diffing npm's registry against the Dockerfile
  pin._ Works, but is a second dependency-tracking mechanism next to
  Dependabot doing the same job for every other pin in this repo — more
  surface area for no real gain over reusing the manifest Dependabot already
  reads.
- _Point Dependabot's `docker` ecosystem at the pin somehow._ Dependabot's
  `docker` ecosystem only parses `FROM` lines; there is no config surface for
  an arbitrary `RUN` line. Not viable.
- _Document it as intentionally manual._ Issue #27 exists precisely because
  that was already true and cost a real gap. Only worth doing if no
  Dependabot-native path existed — one does.

**The Dockerfile reads the version from `package.json` rather than the
Dockerfile carrying its own default.** `COPY package.json ./` into the build
stage, then `bun -e "console.log(require('./package.json').devDependencies.wrangler)"`
to extract the pinned string and feed it to `bun add -g wrangler@<version>`.
This keeps `package.json` the single source of truth: a contributor running
a bare `docker build .` gets the same version CI would, with nothing to pass
as a build arg and nothing to keep in sync by hand. The alternative — a
Dockerfile `ARG WRANGLER_VERSION` with a default — reintroduces exactly the
two-places-to-update problem this change removes, since the default would
need to be bumped in lockstep with `package.json` by hand.

**Exclude `wrangler` from the `bun-dependencies` Dependabot group.** Every
other bun-ecosystem dependency here is dev tooling (biome, commitlint,
lefthook, markdownlint-cli2, prettier) that never ships in the image.
`wrangler` is now the one that does. Grouping it with dev-tooling bumps would
mean a single pull request mixing an image-affecting change with unrelated
tooling churn — worse to review, and it muddies `rules/releases.md`'s
existing distinction between `fix:`-worthy image bumps and `chore:`-worthy
tooling bumps (Dependabot sets one commit-message prefix per ecosystem entry,
not per package, so the whole `bun` entry is already `fix:` — accurate for
`wrangler` specifically now, but was already an approximation for the dev
tooling before this change and stays one after it).

## Risks / Trade-offs

- [`wrangler` becomes a real devDependency, so `bun install` now resolves and
  fetches it locally even though nothing runs it from `node_modules`] →
  Accepted: every other pinned tool here already works this way, and
  wrangler is a normal, if large, npm package.
- [The Dockerfile now depends on `package.json` being present in the build
  context, where before it depended on nothing but itself] → Low risk:
  `package.json` already ships in this repo's root and is not excluded by
  `.dockerignore`.

## Migration Plan

Single pull request: add the devDependency, update the Dockerfile, update
the Dependabot group exclusion, update CONTRIBUTING.md. No running system to
migrate — the next Dependabot scheduled run picks up the new tracking
automatically. No rollback beyond reverting the pull request.
