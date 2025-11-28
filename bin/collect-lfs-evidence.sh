#!/usr/bin/env bash
set -euo pipefail

# collect-lfs-evidence.sh
# Read-only evidence collector for Git LFS state. Writes a tarball to EVID or /tmp.

EVID="${EVID:-/tmp/lfs-evidence}"

# Prefer Make target if present
if command -v make >/dev/null 2>&1 && grep -q '^prepare-evidence:' hunchly.mk 2>/dev/null; then
  echo "[evidence] using Make target to prepare $EVID"
  make -s -f hunchly.mk prepare-evidence EVID="$EVID" || true
else
  echo "[evidence] creating $EVID (fallback)"
  rm -rf "$EVID"
  mkdir -p "$EVID"
  chmod 0755 "$EVID" || true
fi

echo "[evidence] collecting git metadata into $EVID"
git rev-parse --abbrev-ref HEAD > "$EVID/branch.txt" 2>/dev/null || true
git rev-parse --short HEAD > "$EVID/head.txt" 2>/dev/null || true
git status --porcelain=2 -b > "$EVID/status.txt" 2>/dev/null || true
git branch -vv > "$EVID/branches.txt" 2>/dev/null || true
git remote -v > "$EVID/remotes.txt" 2>/dev/null || true
git fetch origin --no-recurse-submodules >/dev/null 2>&1 || true
git rev-list --left-right --count HEAD...origin/$(git rev-parse --abbrev-ref HEAD 2>/dev/null) > "$EVID/divergence.txt" 2>/dev/null || true

git --no-pager lfs --version > "$EVID/git-lfs-version.txt" 2>&1 || true
git lfs ls-files > "$EVID/git-lfs-ls-files.txt" 2>&1 || true
git lfs track > "$EVID/git-lfs-track.txt" 2>&1 || true

git ls-files --stage .gitattributes > "$EVID/gitattributes-index.txt" 2>&1 || true
git show HEAD:.gitattributes > "$EVID/gitattributes-head.txt" 2>&1 || true

git ls-tree -l HEAD media-pack/player > "$EVID/media-pack-ls-tree.txt" 2>&1 || true
git show HEAD:media-pack/player/asciinema-player.min.js | head -c 512 > "$EVID/asciinema-player-head.js" 2>&1 || true
git show HEAD:media-pack/player/asciinema-player.min.css | head -c 512 > "$EVID/asciinema-player-head.css" 2>&1 || true
git show HEAD:media-pack/player/vendor-player.json > "$EVID/vendor-player.json" 2>&1 || true

git grep -n --heading --line-number "version https://git-lfs.github.com/spec/v1" HEAD > "$EVID/lfs-pointer-grep-head.txt" 2>&1 || true
git grep -n --heading --line-number "lfs: true" -- .github/workflows > "$EVID/workflows-lfs-true.txt" 2>&1 || true
git grep -n --heading --line-number "git lfs pull" -- .github/workflows > "$EVID/workflows-lfs-pull.txt" 2>&1 || true

git log --all -S"version https://git-lfs.github.com/spec/v1" --pretty=format:'%H %an %ad %s' > "$EVID/history-pointer-commits.txt" 2>&1 || true

printf "==== git lfs ls-files (trimmed) ====" > "$EVID/summary.txt"
printf "\n" >> "$EVID/summary.txt"
git lfs ls-files | sed -n '1,200p' >> "$EVID/summary.txt" 2>&1 || true
printf "\n==== head of media-pack/player/asciinema-player.min.js ====" >> "$EVID/summary.txt"
printf "\n" >> "$EVID/summary.txt"
head -c 512 "$EVID/asciinema-player-head.js" >> "$EVID/summary.txt" 2>&1 || true
printf "\n==== workflows LFS usage (grep outputs) ====" >> "$EVID/summary.txt"
printf "\n" >> "$EVID/summary.txt"
cat "$EVID/workflows-lfs-true.txt" "$EVID/workflows-lfs-pull.txt" 2>/dev/null >> "$EVID/summary.txt" || true

tar -C "$(dirname "$EVID")" -czf "${EVID}.tar.gz" "$(basename "$EVID")"
echo "Evidence written to: ${EVID} and ${EVID}.tar.gz"
