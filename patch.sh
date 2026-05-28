#!/bin/bash -e
export PATH=/usr/local/opt/gnu-sed/libexec/gnubin:$PATH
# find . -name 'Makefile' -not -path './packages/golang/*' -exec sed  -i '/golang-package.mk/ c\include ../golang/golang-package.mk' {} \;

apply_feed_patches() {
    local patch_root="local-patches/feed"

    [ -d "$patch_root" ] || return 0

    shopt -s nullglob
    for package_patch_dir in "$patch_root"/*; do
        [ -d "$package_patch_dir" ] || continue

        local package_name="${package_patch_dir##*/}"
        local package_dir="packages/$package_name"

        if [ ! -d "$package_dir" ]; then
            echo "Local feed patch target does not exist: $package_dir" >&2
            return 1
        fi

        local patch_files=("$package_patch_dir"/*.patch)
        [ ${#patch_files[@]} -gt 0 ] || continue

        for patch_file in "${patch_files[@]}"; do
            echo "Applying local feed patch: $patch_file"
            patch -d "$package_dir" -p1 --forward < "$patch_file"
        done
    done
}

stage_source_patches() {
    local patch_root="local-patches/source"

    [ -d "$patch_root" ] || return 0

    shopt -s nullglob
    for package_patch_dir in "$patch_root"/*; do
        [ -d "$package_patch_dir" ] || continue

        local package_name="${package_patch_dir##*/}"
        local package_dir="packages/$package_name"
        local target_dir="$package_dir/patches"

        if [ ! -d "$package_dir" ]; then
            echo "Local source patch target does not exist: $package_dir" >&2
            return 1
        fi

        local patch_files=("$package_patch_dir"/*.patch)
        [ ${#patch_files[@]} -gt 0 ] || continue

        mkdir -p "$target_dir"
        cp -f "${patch_files[@]}" "$target_dir"/
    done
}

apply_feed_patches
stage_source_patches

if [[ $1 =~ 'SNAPSHOT'* || $1 =~ '25.12.' ]]; then
    find . -name 'Makefile' -exec sed -i '/PKG_USE_MIPS16:=0/ c\PKG_BUILD_FLAGS:=no-mips16' {} \;
else
    find . -name 'Makefile' -exec sed -i '/PKG_BUILD_FLAGS:=no-mips16/ c\PKG_USE_MIPS16:=0' {} \;
fi
