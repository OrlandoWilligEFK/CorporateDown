#!/bin/bash
# SessionStart hook for CorporateDown.
# Installs R and the package's dependencies so that devtools::document(),
# devtools::test() and devtools::check() work in Claude Code on the web.
# Uses Ubuntu's r-cran-* binary packages (no compilation) for speed.
set -euo pipefail

# Only run in the remote (web) environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

MARKER="/var/lib/corporatedown-deps-installed"
LOG="/tmp/corporatedown-session-start.log"

# Idempotent: skip the heavy install if R + devtools are already usable.
if [ -f "$MARKER" ] && command -v Rscript >/dev/null 2>&1 \
   && Rscript -e 'library(devtools)' >/dev/null 2>&1; then
  echo "CorporateDown dependencies already installed."
  exit 0
fi

echo "Installing R and CorporateDown dependencies (see $LOG)..."

export DEBIAN_FRONTEND=noninteractive

# Ensure R runs in a UTF-8 locale so YAML designs with non-ASCII characters
# (e.g. umlauts) are read correctly. Persist it for the whole session.
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  {
    echo 'export LANG=C.UTF-8'
    echo 'export LC_ALL=C.UTF-8'
  } >> "$CLAUDE_ENV_FILE"
fi

# apt update may warn about unrelated third-party PPAs behind the proxy;
# that must not abort the hook, so ignore its exit status.
apt-get update -qq >>"$LOG" 2>&1 || true

# R itself plus the Imports and Suggests as distro binary packages.
apt-get install -y --no-install-recommends \
  r-base-dev \
  pandoc \
  qpdf \
  r-cran-ggplot2 \
  r-cran-yaml \
  r-cran-systemfonts \
  r-cran-ragg \
  r-cran-cli \
  r-cran-testthat \
  r-cran-knitr \
  r-cran-rmarkdown \
  r-cran-devtools \
  r-cran-roxygen2 \
  r-cran-magick \
  r-cran-patchwork \
  >>"$LOG" 2>&1

mkdir -p "$(dirname "$MARKER")"
touch "$MARKER"
echo "CorporateDown dependencies installed."
