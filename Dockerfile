# Wrangler is installed by bun and run by node. Those are two separate decisions
# and only the first one is the move off pnpm.
#
# Running it under bun is not on the table. On bun's node-compat layer wrangler
# swallows Cloudflare API errors: `wrangler deploy` against a rejected token
# prints its banner, makes the request, and exits 0 - nothing on stderr, and no
# error in wrangler's own log file either. Under node the same command exits 1
# and says why. Not every command does this - `d1 list` reports its error fine -
# which is worse, because a smoke test passes. An image whose only job is
# deploying cannot report a failed deploy as a success.
#
# Keeping node also keeps the `#!/usr/bin/env node` in wrangler's bin script
# honest. oven/bun's images put /usr/local/bun-node-fallback-bin/node -> bun at
# the end of PATH, so a bun-only image satisfies that shebang with bun and hides
# the swap behind a symlink nothing in this file mentions.
FROM oven/bun:1.3.14-alpine@sha256:5acc90a93e91ff07bf72aa90a7c9f0fa189765aec90b47bdbf2152d2196383c0 AS build

# bun's global bin is $BUN_INSTALL/bin - the same shape as pnpm 11's $PNPM_HOME/bin.
# The trap is BUN_INSTALL_BIN, which overrides it outright and which oven's images
# already set to /usr/local/bin. Set only BUN_INSTALL and the install lands in the
# build stage's /usr/local/bin, the COPY below brings across an empty tree, and the
# image builds clean and fails at runtime with "wrangler: not found". Both have to
# be set.
ENV BUN_INSTALL=/opt/wrangler \
    BUN_INSTALL_BIN=/opt/wrangler/bin

RUN bun add -g wrangler@4.120.0

FROM node:26.8.1-alpine@sha256:2d984a15c9b54fd0aeb608b8e0d0d83529eb34d2966db27a1fb4f1edc3d298a3

# curl and ca-certificates aren't wrangler's business - they're here because a
# pipeline step that runs after a deploy (a webhook, a notification) reaches
# for curl assuming any Linux image has it, Alpine doesn't ship it, and the
# failure is easy to miss if that step also has to not fail the job over a
# third party being down.
#
# Pinned versions, not bare `apk add curl ca-certificates` - hadolint DL3018
# wants that everywhere else in this file already. The version has to live in
# an ENV rather than inline in the RUN, because that's what the Repology
# datasource's regex manager in renovate.json matches on to keep both current.
# renovate: datasource=repology depName=alpine_3_24/curl versioning=loose
ENV CURL_VERSION="8.21.0-r0"
# renovate: datasource=repology depName=alpine_3_24/ca-certificates versioning=loose
ENV CA_CERTIFICATES_VERSION="20260611-r0"
RUN apk add --no-cache curl="${CURL_VERSION}" ca-certificates="${CA_CERTIFICATES_VERSION}"

# One prefix, one COPY, and nothing landing in /usr/local to collide with node's
# own files. bun writes the bin entries as symlinks relative to $BUN_INSTALL
# (bin/wrangler -> ../install/global/node_modules/wrangler/bin/wrangler.js), so
# they survive the copy as long as the whole tree moves together.
COPY --from=build /opt/wrangler /opt/wrangler

ENV PATH=/opt/wrangler/bin:$PATH

WORKDIR /app

CMD ["wrangler"]
