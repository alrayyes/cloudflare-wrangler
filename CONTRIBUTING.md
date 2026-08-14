# Contributing

## What a checkout needs

[bun](https://bun.sh) at the version in `.bun-version`, and Docker. Nothing
else — there is no node toolchain here, and the node in the published image is
the image's business rather than yours.

```sh
bun install
```

That also installs the git hooks through lefthook, which is why it's the first
thing to run rather than an optional step.

## The commands

```sh
bun run lint                                          # biome, check only
bun run lint:fix                                      # biome, writing
docker build .
docker compose run --rm -T hadolint hadolint Dockerfile
```

The hooks run those before a commit and a push, and CI runs the same ones, so
CI should rarely be the first to tell you something is wrong.

## The prose

Prose gets linted too — the README and this document — in three tiers over a
formatter. They are the public face of a public repository, so a dead link or a
mangled article is as much a defect as a broken build.

```sh
bun run format          # prettier, writing: markdown and yaml layout
bun run lint:format     # prettier, check only
bun run lint:md         # markdownlint: structure, and an 80 column limit
bun run lint:grammar    # ltex: grammar and spelling. Fails the build
bun run prose:sync      # fetch the pinned vale binary and its styles
bun run lint:prose      # vale: house voice. Errors only
bun run lint:prose:advice
```

Two things about that split are deliberate. **Prettier runs before
markdownlint**, always: Prettier decides layout and markdownlint judges what
Prettier produced, and the other order gets you a hook that fails twice and
fixes nothing. And **LTeX can fail a build where Vale mostly cannot** —
mechanics have a right answer, style is advice, and style that blocks a merge
teaches people `--no-verify`.

`bun run format` fixes almost every Prettier or markdownlint complaint. If
`lint:format` is red, run it rather than arguing with a rule.

A gotcha worth knowing before it costs you a red pipeline: **Vale and LTeX keep
separate dictionaries and neither reads the other.** A new product name or
piece of jargon goes in `styles/config/vocabularies/House/accept.txt` _and_ in
`.ltex.json`, or the tier you forgot fails on its own.

The vocabulary spells tool names the way this project writes them, which is
lowercase — `bun`, `biome`, `hadolint`, as they appear on a command line —
and `Vale.Terms` holds the prose to it rather than merely tolerating it.

`.ltex.json` turns off two rules beyond the usual: `PREPOSITION_VERB`, which
reads "a deploy job" as a mis-conjugated verb rather than a compound noun, and
`PRP_COMMA`, which is comma advice and therefore Vale's business. `LTeX`
reports findings with **exit code 3**, not 1, so anything testing for a
specific code will pass a failing document.

Vale's binary lives in `.tools/` and its Google and proselint styles in
`styles/Google` and `styles/proselint`. All three are fetched by `prose:sync`
and none are committed; only the House vocabulary under `styles/config` is
ours.

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
Work lands through a pull request; nothing is pushed to `main` directly —
`main` is a protected branch, so that is enforced rather than trusted.

**Pull requests are squash merged**, and it is the only method the repository
allows. That is release-please's documented workflow: one pull request becomes
one commit on `main`, and the changelog entry is that commit.

Merge commits were the alternative and they double every entry. GitHub builds a
merge commit's body from the pull request title, so a branch's own
`fix(ci): ...` commit and the merge commit landing it on `main` both parse as
conventional commits, and release-please counts them twice. There is no setting
that avoids it: GitHub allows only three title/body combinations for merge
commits, and each leaves the conventional subject somewhere release-please
reads.

The cost is that a branch built as a readable sequence of commits collapses to
one. So the pull request title carries the weight — it becomes the commit
subject and the changelog line — and the body becomes the commit body. Write
them as though they are the commit, because they are.

## Pinning

Everything is pinned to an exact version and the lockfile is committed:
`devDependencies` without ranges, base images by tag _and_ digest, GitHub
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
