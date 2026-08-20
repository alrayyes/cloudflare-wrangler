# cloudflare-wrangler

[![CI](https://github.com/alrayyes/cloudflare-wrangler/actions/workflows/ci.yml/badge.svg)](https://github.com/alrayyes/cloudflare-wrangler/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/alrayyes/cloudflare-wrangler)](https://github.com/alrayyes/cloudflare-wrangler/releases)
[![licence](https://img.shields.io/github/license/alrayyes/cloudflare-wrangler)](LICENSE)

An image carrying the [Cloudflare wrangler](https://developers.cloudflare.com/workers/wrangler/)
CLI, for CI/CD pipelines that deploy to Cloudflare — so a deploy job stops
installing it on every run. It also carries `curl` and `ca-certificates`,
which Alpine doesn't ship by default, for a step later in the same job that
needs to reach an HTTPS endpoint — a webhook, a notification — without
installing them itself.

```text
ghcr.io/alrayyes/cloudflare-wrangler:latest
```

## Requirements

Docker, and nothing else to pull it. The package is public, so no credentials.

To do anything useful with it you also need a Cloudflare account and an API
token with the permissions for whatever you're deploying. Wrangler reads
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from the environment, which
is the only sane way to pass them to a container.

## Usage

```sh
docker run --rm \
  -e CLOUDFLARE_API_TOKEN -e CLOUDFLARE_ACCOUNT_ID \
  -v "$PWD:/app" \
  ghcr.io/alrayyes/cloudflare-wrangler:latest \
  deploy
```

`/app` is the working directory, so a bind mount there puts your
`wrangler.toml` where wrangler expects to find it. The entrypoint is `wrangler`
itself — pass it subcommands, not a shell.

As the container a CI job runs in:

```yaml
jobs:
  deploy:
    runs-on: ubuntu-24.04
    container:
      image: ghcr.io/alrayyes/cloudflare-wrangler:latest@sha256:...
    steps:
      - uses: actions/checkout@...
      - run: wrangler deploy
        env:
          CLOUDFLARE_API_TOKEN: ${{ secrets.CLOUDFLARE_API_TOKEN }}
```

Pin the digest and let Renovate move it. `latest` on its own is a floating
reference; `latest@sha256:...` is a name for one specific image that a tool can
raise a pull request to change.

Verify where it came from:

```sh
gh attestation verify oci://ghcr.io/alrayyes/cloudflare-wrangler:latest --repo alrayyes/cloudflare-wrangler
```

### Scope

This is a pipeline image. It covers the commands a deploy job runs — `deploy`,
`versions upload`, `pages deploy`, `d1`, `kv`, `secret`, and `deploy --dry-run`
— and local development is not in scope. `wrangler dev` needs `workerd`, a
glibc binary that won't load on musl Alpine; run it on your own machine
instead.

Wrangler is installed by bun and **run by node**, deliberately. Under bun's
node-compat layer wrangler swallows Cloudflare API errors and exits 0 on a
rejected token, which for a deploy image turns a failed deploy into a green
pipeline. The Dockerfile says more about it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
