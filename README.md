# cloudflare-wrangler

[![ci](https://github.com/alrayyes/cloudflare-wrangler/actions/workflows/ci.yml/badge.svg)](https://github.com/alrayyes/cloudflare-wrangler/actions/workflows/ci.yml)
[![release](https://img.shields.io/github/v/release/alrayyes/cloudflare-wrangler)](https://github.com/alrayyes/cloudflare-wrangler/releases)
[![licence](https://img.shields.io/github/license/alrayyes/cloudflare-wrangler)](LICENSE)

An image carrying the [Cloudflare wrangler](https://developers.cloudflare.com/workers/wrangler/)
CLI, so a deploy job stops installing it on every run.

```
ghcr.io/alrayyes/cloudflare-wrangler:latest
```

## Requirements

Docker, and nothing else to pull it. The package is public, so no credentials.

To do anything useful with it you also need a Cloudflare account and an API
token with the permissions for whatever you're deploying. Wrangler reads
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` from the environment, which
is the only sane way to pass them to a container.

## Usage

```
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

```
gh attestation verify oci://ghcr.io/alrayyes/cloudflare-wrangler:latest --repo alrayyes/cloudflare-wrangler
```

### What it can't do

`wrangler dev` does not work here. It needs `workerd`, which ships as a
glibc-linked binary, and this image is built on musl Alpine — the binary is
present and won't load. Everything that runs remotely (`deploy`, `versions
upload`, `d1`, `kv`, `secret`) is fine, and so is `deploy --dry-run`, which
bundles locally without needing a runtime. Local development belongs on your
machine rather than in this container.

Wrangler is installed by bun and **run by node**, deliberately. Under bun's
node-compat layer wrangler swallows Cloudflare API errors and exits 0 on a
rejected token, which for a deploy image turns a failed deploy into a green
pipeline. The Dockerfile says more about it.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md).

## Licence

GPL-3.0-or-later. See [LICENSE](LICENSE).
