#!/usr/bin/env bash
# ============================================================================
# Developer machine onboarding — public entry point.
# ============================================================================
# Fresh Mac:
#   ORG=<org> REPO=<repo> bash -c "$(curl -fsSL https://raw.githubusercontent.com/bewith-dev/onboarding/master/install.sh)"
#
# Minimal and generic on purpose. It installs a standard toolchain (Xcode CLT,
# Homebrew, gh), signs you in to YOUR GitHub account, then clones the private
# repo named by $ORG/$REPO and hands off to its bootstrap. Anyone who runs this
# without access to that org just gets gh + their own GitHub login; the clone
# fails and nothing internal is revealed. Re-running is safe — every step
# skips or repairs, never destroys.
# ============================================================================
set -euo pipefail
if [[ -e /dev/tty ]] && [[ ! -t 0 ]]; then exec </dev/tty; fi

BOLD=$'\033[1m'; RESET=$'\033[0m'
BLUE=$'\033[34m'; GREEN=$'\033[32m'; YELLOW=$'\033[33m'; RED=$'\033[31m'
log()  { printf "${BLUE}${BOLD}▸${RESET} %s\n" "$*"; }
ok()   { printf "${GREEN}✓${RESET} %s\n" "$*"; }
warn() { printf "${YELLOW}!${RESET} %s\n" "$*"; }
err()  { printf "${RED}✗${RESET} %s\n" "$*" >&2; exit 1; }

# org / repo come from the environment (set in the one-liner you were given) or
# you're prompted. Nothing org-specific is hardcoded in this script.
ORG="${ORG:-}"
REPO="${REPO:-}"

printf "\n${BOLD}Developer machine onboarding${RESET}\n\n"

# ---- 1. Xcode Command Line Tools (provides git) ----------------------------
# Try a headless install first (no dialog, no re-run needed); fall back to the
# GUI installer + re-run only if softwareupdate can't find/install it.
if ! xcode-select -p >/dev/null 2>&1; then
  log "Installing Xcode Command Line Tools (this can take 5-15 min)..."
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  clt_label="$(softwareupdate -l 2>/dev/null | grep -E 'Label:.*Command Line Tools' | head -1 | sed -E 's/.*Label: *//')"
  if [[ -n "$clt_label" ]]; then
    log "Headless install: $clt_label"
    softwareupdate -i "$clt_label" --verbose 2>/dev/null || true
  fi
  rm -f /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
  if ! xcode-select -p >/dev/null 2>&1; then
    # Headless didn't take — open the GUI installer and ask for one re-run.
    xcode-select --install 2>/dev/null || true
    warn "A dialog opened — click Install, then Agree (~5-15 min)."
    warn "When it finishes, re-run this: press the Up-arrow key, then Enter."
    exit 0
  fi
fi
ok "Xcode Command Line Tools present"

# ---- 2. Homebrew + gh ------------------------------------------------------
if ! command -v brew >/dev/null 2>&1; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[[ -d /opt/homebrew/bin ]] && export PATH="/opt/homebrew/bin:$PATH"
command -v gh >/dev/null 2>&1 || { log "Installing GitHub CLI..."; brew install gh; }
ok "Homebrew + gh present"

# ---- 3. GitHub sign-in (your own account) ----------------------------------
if ! gh auth status >/dev/null 2>&1; then
  log "Signing you in to GitHub (a browser window will open)..."
  gh auth login --git-protocol https --web --hostname github.com \
    --scopes "admin:public_key,read:packages,workflow"
fi
gh auth setup-git
ok "Signed in as $(gh api user --jq .login 2>/dev/null || echo '?')"

# ---- 4. Resolve org/repo (prompt if not supplied) --------------------------
[[ -n "$ORG"  ]] || read -r -p "  GitHub org:  " ORG
[[ -n "$REPO" ]] || read -r -p "  Repo name:   " REPO
[[ -n "$ORG" && -n "$REPO" ]] || err "org and repo are required."
TARGET="${SANDBOX_DIR:-$HOME/workspace/$REPO}"

# ---- 5. Clone (fails cleanly without access) -------------------------------
mkdir -p "$(dirname "$TARGET")"
if [[ -d "$TARGET/.git" ]]; then
  log "Already at $TARGET — updating..."
  git -C "$TARGET" pull --ff-only 2>/dev/null || warn "Couldn't fast-forward — leaving as-is."
else
  log "Cloning ${ORG}/${REPO}..."
  gh repo clone "${ORG}/${REPO}" "$TARGET" >/dev/null 2>&1 \
    || err "Couldn't clone ${ORG}/${REPO} — you need access to that org. Ask your team."
fi
ok "Repo ready at $TARGET"

# ---- 6. Hand off to the repo's bootstrap -----------------------------------
BOOTSTRAP="$TARGET/onboarding/bootstrap.sh"
[[ -f "$BOOTSTRAP" ]] || err "Expected $BOOTSTRAP after clone — repo layout may have changed."
printf "\n${GREEN}${BOLD}Toolchain ready.${RESET}\n\n"
# Don't leak ORG/REPO into the bootstrap — tools it runs read $REPO (the
# oh-my-zsh installer would otherwise try to clone github.com/sandbox). Preserve
# AUTO_BOOTSTRAP's value, then clear all of ours before handing off.
_auto="${AUTO_BOOTSTRAP:-0}"
unset ORG REPO SANDBOX_DIR AUTO_BOOTSTRAP
[[ "$_auto" == "1" ]] && exec bash "$BOOTSTRAP"
read -r -p "  Run the machine bootstrap now? [Y/n] " _ans
[[ -z "$_ans" || "$_ans" =~ ^[Yy] ]] && exec bash "$BOOTSTRAP"
printf "\n  Run it when ready:\n    ${BOLD}cd %s/onboarding && bash bootstrap.sh${RESET}\n\n" "$TARGET"
