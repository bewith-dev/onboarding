# BeWith — developer machine onboarding

Public entry point for setting up a new Mac for BeWith development. One command
installs a standard toolchain, signs you in to your own GitHub account, clones
the team repo you have access to, and hands off to that repo's bootstrap.

## Quick start

On a fresh Mac, open Terminal and run:

```sh
ORG=bewith-dev REPO=sandbox bash -c "$(curl -fsSL https://raw.githubusercontent.com/bewith-dev/onboarding/master/install.sh)"
```

That's it. The rest is interactive and safe to re-run.

## What it does

1. Installs Xcode Command Line Tools (provides `git`).
2. Installs Homebrew and the GitHub CLI (`gh`).
3. Signs you in to **your own** GitHub account (`gh auth login`, opens a browser).
4. Clones the private `$ORG/$REPO` repo to `~/workspace/$REPO`.
5. Hands off to that repo's `onboarding/bootstrap.sh`, which provisions the rest.

## Why this repo is safe to be public

This repo contains only the bootstrap entry point — `install.sh` — and this
README. There is deliberately nothing sensitive here:

- **No secrets, tokens, or credentials.** Authentication is your own GitHub
  login via `gh`; nothing is embedded in the script.
- **Nothing org-specific is hardcoded.** The org and repo come from the
  environment (or an interactive prompt). The script is generic.
- **No access leak.** Anyone who runs it without access to the target org just
  gets `gh` plus their own GitHub login; the clone fails with a plain message
  and nothing internal is revealed.
- **Idempotent.** Every step detects "already done" and skips or repairs —
  re-running never destroys anything.

The script is short and meant to be read before you run it. The actual
onboarding logic lives in the (private) target repo under
`onboarding/bootstrap.sh`.
