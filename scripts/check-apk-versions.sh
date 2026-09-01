#!/usr/bin/env sh
# Bumps the curl/ca-certificates apk pins in the Dockerfile to whatever the
# image's own Alpine branch currently has, in place. Run from the repo root.
#
# Neither Renovate (never reaches this repo, #28) nor Dependabot (its docker
# ecosystem only reads FROM lines) tracks these - see #29. The Alpine branch
# is read out of the pinned node base image itself, rather than hardcoded,
# so this keeps working the day that base image moves to a newer Alpine.
set -eu

DIGEST=$(awk -F'@' '/^FROM node:/{print $2}' Dockerfile)
ALPINE_VERSION=$(docker run --rm "node@${DIGEST}" sh -c \
  '. /etc/os-release && echo "$VERSION_ID"')
# 3.24.1 -> v3.24. Alpine publishes one APKINDEX per minor branch, not per
# patch release.
ALPINE_BRANCH="v$(echo "$ALPINE_VERSION" | cut -d. -f1,2)"

INDEX_URL="https://dl-cdn.alpinelinux.org/alpine/${ALPINE_BRANCH}/main/x86_64/APKINDEX.tar.gz"
INDEX=$(mktemp -d)
curl -sSfL "$INDEX_URL" | tar xz -C "$INDEX" APKINDEX

# The index is a flat text file, one blank-line-separated stanza per
# package: P: is the name, V: the pinned version-release.
latest_version() {
  awk -v pkg="$1" '
    $0 == "P:" pkg { found=1 }
    found && /^V:/ { print substr($0, 3); exit }
  ' "$INDEX/APKINDEX"
}

CURL_LATEST=$(latest_version curl)
CA_CERTIFICATES_LATEST=$(latest_version ca-certificates)
rm -rf "$INDEX"

if [ -z "$CURL_LATEST" ] || [ -z "$CA_CERTIFICATES_LATEST" ]; then
  echo "could not find curl or ca-certificates in ${INDEX_URL}" >&2
  exit 1
fi

sed -i \
  -e "s/^ENV CURL_VERSION=\".*\"/ENV CURL_VERSION=\"${CURL_LATEST}\"/" \
  -e "s/^ENV CA_CERTIFICATES_VERSION=\".*\"/ENV CA_CERTIFICATES_VERSION=\"${CA_CERTIFICATES_LATEST}\"/" \
  Dockerfile

echo "curl -> ${CURL_LATEST}, ca-certificates -> ${CA_CERTIFICATES_LATEST} (${ALPINE_BRANCH})"
