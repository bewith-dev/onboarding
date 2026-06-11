#!/usr/bin/env bash
# ============================================================================
# BeWith CLI — install / update only.
# ============================================================================
# For someone already set up in the company who just wants the `bewith` CLI.
# One command — no PAT, no repo clone, no full machine bootstrap:
#
#   bash -c "$(curl -fsSL https://raw.githubusercontent.com/bewith-dev/onboarding/master/cli.sh)"
#
# Installs (or updates) @bewith-dev/cli from GitHub Packages, authenticating
# with your existing `gh` login. Re-running just upgrades to @latest. For a
# fresh Mac (toolchain + repos + stack) use install.sh instead. Re-running is
# safe — every step detects "already done".
# ============================================================================
set -euo pipefail

BOLD=$'\033[1m'; RESET=$'\033[0m'
BLUE=$'\033[34m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
log()  { printf "${BLUE}${BOLD}▸${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %s\n" "$*"; }
err()  { printf "${RED}✗${RESET} %s\n" "$*" >&2; exit 1; }

printf "\n${BOLD}BeWith CLI — install / update${RESET}\n\n"

# ---- 1. Node >= 20 ---------------------------------------------------------
command -v node >/dev/null 2>&1 \
  || err "Node.js not found. Install Node 20+ (nvm, or 'brew install node'), then re-run."
node_major="$(node -p 'process.versions.node.split(".")[0]' 2>/dev/null || echo 0)"
[[ "$node_major" -ge 20 ]] || err "Node $(node -v) is too old — need v20+. Upgrade and re-run."
ok "Node $(node -v)"

# ---- 2. GitHub CLI, signed in ----------------------------------------------
command -v gh >/dev/null 2>&1 || err "GitHub CLI not found. 'brew install gh', then 'gh auth login'."
gh auth status >/dev/null 2>&1 || err "Not signed in to GitHub. Run: gh auth login"
ok "Signed in as $(gh api user --jq .login 2>/dev/null || echo '?')"

# ---- 3. ~/.npmrc — @bewith-dev scope (token injected at install, not stored) -
NPMRC="$HOME/.npmrc"
if grep -q "@bewith-dev:registry" "$NPMRC" 2>/dev/null; then
  ok "$NPMRC already has the @bewith-dev scope"
else
  log "Adding the @bewith-dev scope to $NPMRC ..."
  if [[ -f "$NPMRC" ]]; then cp "$NPMRC" "$NPMRC.bak"; fi
  {
    echo "@bewith-dev:registry=https://npm.pkg.github.com/"
    echo '//npm.pkg.github.com/:_authToken=${NODE_AUTH_TOKEN}'
  } >> "$NPMRC"
  ok "$NPMRC configured"
fi

# ---- 4. Install / update ---------------------------------------------------
log "Installing @bewith-dev/cli@latest (token injected for this command only)..."
NODE_AUTH_TOKEN="$(gh auth token)" npm i -g @bewith-dev/cli@latest \
  || err "Install failed — confirm your GitHub account is in the bewith-dev org with read:packages."
ok "bewith $(bewith --version 2>/dev/null || echo installed)"

printf "\n${GREEN}${BOLD}Done.${RESET}  Try ${BOLD}bewith --help${RESET}  ·  add the Claude plugin with ${BOLD}bewith claude install${RESET}\n\n"
