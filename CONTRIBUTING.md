# Contributing

## What a checkout needs

[bun](https://bun.sh) at the version in `.bun-version`, and Docker. Nothing
else — there is no node toolchain here, and the node in the published image is
the image's business rather than yours.

```
bun install
```

That also installs the git hooks through lefthook, which is why it's the first
thing to run rather than an optional step.

## The commands

```
bun run lint                                          # biome, check only
bun run lint:fix                                      # biome, writing
docker build .
docker compose run --rm -T hadolint hadolint Dockerfile
```

The hooks run those before a commit and a push, and CI runs the same ones, so
CI should rarely be the first to tell you something is wrong.

CI also runs checks against the built image that the hooks don't: that
`wrangler --version` works, that the runtime is node and not bun, that bun
isn't in the final layer, and that a worker still bundles. See
`.github/workflows/ci.yml`.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/), enforced by
commitlint in the `commit-msg` hook and again on the pull request. This isn't
housekeeping: release-please reads those messages to decide the next version,
so a commit that doesn't parse doesn't get a worse changelog entry, it gets
none, and the version doesn't move.

`fix:` and `feat:` cut a release. Everything else doesn't.

One logical change per commit, and one reviewable change per pull request.
Work lands through a pull request; nothing is pushed to `main` directly.

## Pinning

Everything is pinned to an exact version and the lockfile is committed:
`devDependencies` without ranges, base images by tag *and* digest, GitHub
Actions by commit SHA with a `# vX.Y.Z` comment beside them. Renovate reads
that comment to know what to bump, so keep it.

The wrangler version lives in the `bun add -g wrangler@...` line in the
Dockerfile and is bumped by a custom Renovate manager matching that exact
string. If you reword that line, update `renovate.json` with it or wrangler
silently stops being updated.

Renovate raises image-affecting bumps as `fix(deps):` rather than the default
`chore(deps):`, so they cut a release and republish. Tooling bumps stay
`chore(deps):` — biome isn't in the image, so a new biome shouldn't produce a
new tag.

## Releasing

Nobody picks a version. release-please keeps a release pull request open
carrying the next version and the changelog entry; merging it tags the release,
and the same run builds the image, pushes it to `ghcr.io` and attests its
provenance.

Tags are bare semver — `1.0.178`, not `v1.0.178`.

## Where this came from

Everything up to 1.0.177 was released from a self-hosted GitLab that no longer
exists. That history isn't in this repository: it was squashed into a single
import commit, because the commits behind it were authored by bots at internal
hostnames and referenced an internal registry, and this repository is public.
The changelog entries are kept, but their links are gone — there's nothing left
for them to point at.
