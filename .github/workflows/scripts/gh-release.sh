#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d dist ]]; then
  echo "dist directory does not exist" >&2
  exit 1
fi

build_time="$(date -u '+%Y-%m-%d %H:%M:%S UTC')"
commit_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/commit/${GITHUB_SHA}"
run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"
short_sha="${GITHUB_SHA::12}"
notes_dir="$(mktemp -d)"
release_count=0
trap 'rm -rf "$notes_dir"' EXIT

while IFS= read -r -d '' feed_dir; do
  rel_path="${feed_dir#dist/}"
  version_dir="${rel_path%%/*}"
  arch_and_feed="${rel_path#*/}"
  arch="${arch_and_feed%%/*}"
  feedname="${arch_and_feed#*/}"

  if [[ "$version_dir" != packages-* || -z "$arch" || -z "$feedname" || "$feedname" == "$arch_and_feed" ]]; then
    echo "Skipping unexpected package directory: ${rel_path}" >&2
    continue
  fi

  version="${version_dir#packages-}"
  tag="${version_dir}/${arch}/${feedname}"
  notes_file="${notes_dir}/${version_dir}-${arch}-${feedname}.md"

  mapfile -d '' all_files < <(find "$feed_dir" -maxdepth 1 -type f -print0 | sort -z)
  if (( ${#all_files[@]} == 0 )); then
    echo "Skipping empty package directory: ${rel_path}"
    continue
  fi

  assets=()
  for f in "${all_files[@]}"; do
    if [[ -s "$f" ]]; then
      assets+=("$f")
    else
      echo "Skipping empty file: ${f##*/}"
    fi
  done
  if (( ${#assets[@]} == 0 )); then
    echo "Skipping directory with only empty files: ${rel_path}"
    continue
  fi

  declare -A wanted_assets=()
  for asset in "${assets[@]}"; do
    wanted_assets["${asset##*/}"]=1
  done

  pkg_count=0
  for asset in "${assets[@]}"; do
    case "${asset##*/}" in
      *.apk|*.ipk) pkg_count=$((pkg_count + 1)) ;;
    esac
  done

  {
    printf '# %s\n\n' "$tag"
    printf '| Field | Value |\n'
    printf '| --- | --- |\n'
    printf '| Build time (UTC) | %s |\n' "$build_time"
    printf '| OpenWrt version | %s |\n' "$version"
    printf '| Architecture | `%s` |\n' "$arch"
    printf '| Feed | `%s` |\n' "$feedname"
    printf '| Packages | %d |\n' "$pkg_count"
    printf '| Source commit | [`%s`](%s) |\n' "$short_sha" "$commit_url"
    printf '| Workflow Run | [#%s](%s) |\n' "$GITHUB_RUN_NUMBER" "$run_url"
  } > "$notes_file"

  if gh release view "$tag" >/dev/null 2>&1; then
    echo "Updating GitHub Release: ${tag}"
    gh release edit "$tag" --title "$tag" --notes-file "$notes_file" --target "$GITHUB_SHA" --latest=false

    while IFS= read -r existing_asset; do
      [[ -n "$existing_asset" ]] || continue
      if [[ -z "${wanted_assets[$existing_asset]+x}" ]]; then
        echo "Deleting stale asset from ${tag}: ${existing_asset}"
        gh release delete-asset "$tag" "$existing_asset" --yes
      fi
    done < <(gh release view "$tag" --json assets --jq '.assets[].name')
  else
    echo "Creating GitHub Release: ${tag}"
    gh release create "$tag" --title "$tag" --notes-file "$notes_file" --target "$GITHUB_SHA" --latest=false
  fi

  for asset in "${assets[@]}"; do
    echo "Uploading ${asset##*/} to ${tag}"
    gh release upload "$tag" "$asset" --clobber
  done

  release_count=$((release_count + 1))
  unset wanted_assets
done < <(find dist -mindepth 3 -maxdepth 3 -type d -print0 | sort -z)

if (( release_count == 0 )); then
  echo "No package feed directories with files were found under dist" >&2
  exit 1
fi

echo "Published ${release_count} GitHub package releases."
