#!/usr/bin/env bash
# Creates local, tool-specific agent files from the committed AGENTS.md and
# .agents/ directory. Nothing created here is committed: every path is listed
# in .git/info/exclude. Safe to re-run; it also refreshes the organisation guide.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

exclude="$(git rev-parse --git-path info/exclude)"
mkdir -p "$(dirname "$exclude")"
touch "$exclude"

hide() {
  grep -qxF "$1" "$exclude" || printf '%s\n' "$1" >> "$exclude"
}

# Claude Code: CLAUDE.md imports AGENTS.md.
if [ -e CLAUDE.md ]; then
  echo "kept    CLAUDE.md (already exists)"
else
  printf '@AGENTS.md\n' > CLAUDE.md
  hide "/CLAUDE.md"
  echo "created CLAUDE.md"
fi

# Claude Code reads skills from .claude/skills; point it at the shared ones.
if [ -e .claude/skills ] || [ -L .claude/skills ]; then
  echo "kept    .claude/skills (already exists)"
else
  mkdir -p .claude
  ln -s ../.agents/skills .claude/skills
  hide "/.claude/skills"
  echo "created .claude/skills -> ../.agents/skills"
fi

# Local copy of the organisation contributing guide, so agents read it from
# disk instead of fetching it. The organisation repository is private: this
# needs an authenticated GitHub CLI.
guide=".agents/org-contributing.md"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
if command -v gh >/dev/null 2>&1 &&
  gh api repos/Nucleo-Estudantes-Informatica-ISEP/.github/contents/CONTRIBUTING.md \
    -H "Accept: application/vnd.github.raw" > "$tmp" 2>/dev/null; then
  {
    printf '<!-- Synced from Nucleo-Estudantes-Informatica-ISEP/.github on %s. Re-run scripts/agents/setup.sh to refresh. -->\n\n' "$(date -u +%F)"
    cat "$tmp"
  } > "$guide"
  hide "/$guide"
  echo "synced  $guide"
else
  echo "skipped $guide (needs an authenticated gh CLI: run 'gh auth login')" >&2
fi
