#!/usr/bin/env bash
# Creates local, tool-specific agent files from the committed AGENTS.md and
# .agents/ directory. Nothing created here is committed: every path is listed
# in .git/info/exclude. Safe to re-run.
#
# On Windows, run scripts\agents\setup.bat <agent>... (needs Git Bash), or run
# this script from Git Bash or WSL.
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: scripts/agents/setup.sh [--no-guide] <agent>...

Agents:
  claude   create CLAUDE.md and .claude/skills
  gemini   create GEMINI.md
  codex    reads AGENTS.md and .agents/skills natively, nothing to create
  cursor   reads AGENTS.md natively, nothing to create
  copilot  reads AGENTS.md natively, nothing to create
  all      claude and gemini

Options:
  --no-guide  do not copy the organisation contributing guide
  -h, --help  show this help
USAGE
}

guide=1
agents=""
for arg in "$@"; do
  case "$arg" in
    -h | --help) usage; exit 0 ;;
    --no-guide) guide=0 ;;
    all) agents="$agents claude gemini" ;;
    claude | gemini | codex | cursor | copilot) agents="$agents $arg" ;;
    *) echo "error: unknown argument '$arg'" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$agents" ]; then
  echo "error: name at least one agent" >&2
  usage >&2
  exit 2
fi

cd "$(git rev-parse --show-toplevel)"

exclude="$(git rev-parse --git-path info/exclude)"
mkdir -p "$(dirname "$exclude")"
touch "$exclude"

hide() {
  grep -qxF "$1" "$exclude" || printf '%s\n' "$1" >> "$exclude"
}

# Creates a file that imports AGENTS.md. Never overwrites an existing file.
create_import_file() {
  if [ -e "$1" ]; then
    echo "kept    $1 (already exists)"
  else
    printf '%s\n' "$2" > "$1"
    hide "/$1"
    echo "created $1"
  fi
}

# Points a tool's skills directory at .agents/skills. Falls back to a copy
# where symlinks are unavailable (Windows without Developer Mode).
link_skills() {
  target="$1"
  link_to="$2"
  if [ -L "$target" ]; then
    echo "kept    $target"
    return
  fi
  if [ -e "$target" ]; then
    if [ -f "$target/.copied-by-setup" ]; then
      rm -rf "$target"
    else
      echo "kept    $target (already exists)"
      return
    fi
  fi
  mkdir -p "$(dirname "$target")"
  if ln -s "$link_to" "$target" 2>/dev/null && [ -L "$target" ]; then
    echo "created $target -> $link_to"
  else
    rm -rf "$target"
    cp -R .agents/skills "$target"
    touch "$target/.copied-by-setup"
    echo "created $target (copy, symlinks unavailable: re-run setup after .agents/skills changes)"
  fi
  hide "/$target"
}

for agent in $agents; do
  case "$agent" in
    claude)
      create_import_file CLAUDE.md "@AGENTS.md"
      link_skills .claude/skills ../.agents/skills
      ;;
    gemini)
      create_import_file GEMINI.md "@./AGENTS.md"
      ;;
    codex)
      echo "codex   reads AGENTS.md and .agents/skills natively, nothing to create"
      ;;
    cursor | copilot)
      echo "$agent reads AGENTS.md natively, nothing to create"
      ;;
  esac
done

# Local copy of the organisation contributing guide, so agents read it from
# disk instead of fetching it. The organisation repository is private: this
# needs an authenticated GitHub CLI.
if [ "$guide" -eq 1 ]; then
  guide_file=".agents/org-contributing.md"
  tmp="$(mktemp)"
  trap 'rm -f "$tmp"' EXIT
  if command -v gh >/dev/null 2>&1 &&
    gh api repos/Nucleo-Estudantes-Informatica-ISEP/.github/contents/CONTRIBUTING.md \
      -H "Accept: application/vnd.github.raw" > "$tmp" 2>/dev/null; then
    {
      printf '<!-- Synced from Nucleo-Estudantes-Informatica-ISEP/.github on %s. Re-run scripts/agents/setup.sh to refresh. -->\n\n' "$(date -u +%F)"
      cat "$tmp"
    } > "$guide_file"
    hide "/$guide_file"
    echo "synced  $guide_file"
  else
    echo "skipped $guide_file (needs an authenticated gh CLI: run 'gh auth login')" >&2
  fi
fi
