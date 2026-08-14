FROM node:24.19.0-alpine@sha256:d32cdf619f63fe0471182d08996dd516c6275bb5fd31ae06e55a570bd9e1ad43

# pnpm 11 puts global binaries in $PNPM_HOME/bin, where pnpm 10 put them straight
# into $PNPM_HOME. So this has to name the *parent* of a directory already on
# PATH: /usr/local gives /usr/local/bin. Setting it to /usr/sbin, which worked on
# pnpm 10, now fails the build outright with "global bin directory not in PATH".
ENV PNPM_HOME=/usr/local

RUN corepack enable  \
    && corepack prepare pnpm@11.21.0 --activate \
    && pnpm add -g wrangler@4.120.0

WORKDIR /app

CMD ["wrangler"]
