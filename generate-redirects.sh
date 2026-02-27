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

    # Compute the relative prefix to get back to the component root.
    # e.g., "about/team.html" needs "../" to reach the component dir.
    dir_part=$(dirname "$rel_path")
    prefix=""
    if [ "$dir_part" != "." ]; then
      # Replace each path segment with ".."
      prefix=$(echo "$dir_part" | sed 's|[^/]*|..|g')/
    fi
    redirect_url="${prefix}latest/${rel_path}"

    mkdir -p "$(dirname "$target")"

    cat > "$target" <<EOF
<!DOCTYPE html>
<meta charset="utf-8">
<link rel="canonical" href="${redirect_url}">
<script>location="${redirect_url}"</script>
<meta http-equiv="refresh" content="0; url=${redirect_url}">
<meta name="robots" content="noindex">
<title>Redirect</title>
<a href="${redirect_url}">${redirect_url}</a>
EOF

    echo "  redirect: ${component}/${rel_path} -> ${component}/latest/${rel_path}"
  done
done
