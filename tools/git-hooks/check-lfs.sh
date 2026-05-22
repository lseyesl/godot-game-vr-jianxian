#!/usr/bin/env bash
set -e

MAX_SIZE=$((10 * 1024 * 1024))

git diff --cached --name-only --diff-filter=AM | while read -r file; do
  [ -f "$file" ] || continue

  size=$(wc -c <"$file")

  if [ "$size" -gt "$MAX_SIZE" ]; then
    if ! git check-attr filter -- "$file" | grep -q "filter: lfs"; then
      echo "❌ Large file not tracked by Git LFS: $file"
      echo "Run: git lfs track \"$file\""
      exit 1
    fi
  fi
done
