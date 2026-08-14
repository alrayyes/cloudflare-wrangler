#!/usr/bin/env sh
# Grammar and spelling, over the documents a human wrote.
#
# One script so the pre-push hook and the CI job run the same command. A linter
# whose invocation lives inline in the workflow is the one that ends up missing
# from the hooks, and the copy that knows less is the one that fails a commit
# over prose nobody wrote.
#
# The release is a ~300MB archive carrying its own Java, so it is cached outside
# the repository and fetched once. After that a run over three documents is
# about ten seconds, which is why this is in pre-push rather than left to CI.
set -eu

VERSION="18.7.0"
CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/ltex-ls-plus"
HOME_DIR="${CACHE}/${VERSION}/ltex-ls-plus-${VERSION}"

if [ ! -x "${HOME_DIR}/bin/ltex-cli-plus" ]; then
	echo "Fetching ltex-ls-plus ${VERSION} into ${CACHE}"
	mkdir -p "${CACHE}/${VERSION}"
	curl -sSfL \
		"https://github.com/ltex-plus/ltex-ls-plus/releases/download/${VERSION}/ltex-ls-plus-${VERSION}-linux-x64.tar.gz" \
		| tar xz -C "${CACHE}/${VERSION}"
fi

# The launcher is a Gradle start script and prefers JAVA_HOME over the runtime
# shipped beside it. A GitHub runner sets JAVA_HOME to its own Java 17, the
# class files are version 65, and 17 reads up to 61 - so it fails to load
# rather than falling back. Point it at the JDK that came in the archive.
JAVA_HOME="$(ls -d "${HOME_DIR}"/jdk-*)"
export JAVA_HOME

# The files are named rather than passing `.`: LTeX traverses recursively and
# reads plain text as prose, so a bare dot lints the committed Vale vocabulary
# as though it were a document. CHANGELOG.md is left out because release-please
# writes it from commit subjects and nobody can fix it in place.
#
# It reports findings with exit code 3, not 1. `set -e` catches any non-zero,
# which is the right test - anything checking for 1 specifically would pass a
# failing document.
exec "${HOME_DIR}/bin/ltex-cli-plus" \
	--client-configuration=.ltex.json \
	README.md CONTRIBUTING.md
