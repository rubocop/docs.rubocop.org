#!/usr/bin/env bash
# Generate HTML redirect files from old unversioned URLs to latest/.
# Runs after the Antora build to preserve existing links and bookmarks.

set -euo pipefail

SITE_DIR="build/site"

for component_dir in "$SITE_DIR"/*/; do
  latest_dir="${component_dir}latest"
  [ -d "$latest_dir" ] || continue

  component=$(basename "$component_dir")

  find "$latest_dir" -name '*.html' -type f | while read -r file; do
    rel_path="${file#"$latest_dir"/}"
    target="${component_dir}${rel_path}"

    # Don't overwrite existing files (e.g., versioned pages or Antora redirects)
    [ -e "$target" ] && continue

    mkdir -p "$(dirname "$target")"

    cat > "$target" <<EOF
<!DOCTYPE html>
<meta charset="utf-8">
<link rel="canonical" href="latest/${rel_path}">
<script>location="latest/${rel_path}"</script>
<meta http-equiv="refresh" content="0; url=latest/${rel_path}">
<meta name="robots" content="noindex">
<title>Redirect</title>
<a href="latest/${rel_path}">latest/${rel_path}</a>
EOF

    echo "  redirect: ${component}/${rel_path} -> ${component}/latest/${rel_path}"
  done
done
