## 1. Manifest

- [x] 1.1 Add `wrangler` to `package.json`'s `devDependencies`, pinned to
      the version currently in the Dockerfile, and verify `bun install`
      (pinned toolchain) resolves it and updates `bun.lock` cleanly
- [x] 1.2 Verify `bun install --frozen-lockfile` passes against the
      committed `bun.lock`

## 2. Dockerfile

- [x] 2.1 `COPY package.json` into the build stage and read the pinned
      `wrangler` version from it at build time instead of hardcoding it in
      the `bun add -g` line
- [x] 2.2 Verify `docker build .` succeeds and the built image's
      `wrangler --version` reports the version pinned in `package.json`
- [x] 2.3 Verify hadolint stays clean on the changed Dockerfile

## 3. Dependabot

- [x] 3.1 Add `wrangler` to the `bun-dependencies` group's
      `exclude-patterns` in `.github/dependabot.yml`, so it always opens
      its own pull request

## 4. Docs

- [x] 4.1 Update CONTRIBUTING.md's Pinning section to describe the new
      mechanism instead of the removed Renovate manager
- [x] 4.2 Verify `bun run lint:format`, `bun run lint:md` and
      `bun run lint:grammar` pass on the changed CONTRIBUTING.md

## 5. Close-out

- [x] 5.1 Close #27, referencing the pull request that shipped this
