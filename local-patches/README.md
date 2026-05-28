# Local patches

`sync.yml` regenerates `packages/` from upstream feeds, so local fixes live outside that directory and are applied during the build workflow by `patch.sh`.

- `feed/<package>/*.patch` patches the package directory itself, such as `Makefile` metadata.
- `source/<package>/*.patch` is copied to `packages/<package>/patches/` so OpenWrt applies it to the upstream source tree.

Patch files are applied in shell glob order. Prefix filenames with numbers when order matters.
