set -euo pipefail

echo "[who/where]"
git rev-parse --show-toplevel
git status -sb

echo
echo "[roots]"
echo -n "HEAD roots count: "
git rev-list --max-parents=0 HEAD | wc -l | tr -d ' '
echo "HEAD root(s):"
git rev-list --max-parents=0 --abbrev-commit HEAD

echo
echo "[main root]"
git rev-list --max-parents=0 --abbrev-commit main

echo
echo "[is 57328c6 reachable from HEAD?]"
git merge-base --is-ancestor 57328c6 HEAD && echo "YES" || echo "NO"

echo
echo "[is convert-lfs-tip related to current branch?]"
git merge-base --all convert-lfs-tip-on-main convert-lfs-tip || echo "no common ancestor"

echo
echo "[commits unique to convert-lfs-tip-on-main vs main]"
git log --oneline --ancestry-path main..convert-lfs-tip-on-main
