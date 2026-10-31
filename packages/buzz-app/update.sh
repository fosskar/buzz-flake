#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#git nixpkgs#gnused nixpkgs#gnugrep nixpkgs#coreutils nixpkgs#nix nixpkgs#jq -c bash
# shellcheck shell=bash
#
# Moves the block/buzz-app pin to the newest `desktop-vX.Y.Z` tag (no betas,
# no previews), follows its goose pin, and refreshes the hashes in source.nix.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." &>/dev/null && pwd)"
source_nix="$SCRIPT_DIR/source.nix"
repo_url="https://github.com/block/buzz-app"

# git ls-remote instead of the GitHub API: the tags have no release objects,
# and ls-remote is not rate limited.
tag="$(git ls-remote --tags --refs "$repo_url" 'desktop-v*' |
  sed -n 's|^[0-9a-f]*[[:space:]]*refs/tags/\(desktop-v[0-9]*\.[0-9]*\.[0-9]*\)$|\1|p' |
  sort -V | tail -1)"
if [[ -z $tag ]]; then
  echo "could not determine the latest desktop-v* tag" >&2
  exit 1
fi

latest="${tag#desktop-v}"
current="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$source_nix" | head -1)"
if [[ $current == "$latest" ]]; then
  echo ":: buzz-app already at $latest"
  exit 0
fi

# the tags are annotated; ^{} peels them to the commit
rev="$(git ls-remote "$repo_url" "refs/tags/$tag^{}" | cut -f1)"
if [[ -z $rev ]]; then
  echo "could not resolve $tag to a commit" >&2
  exit 1
fi

src_hash="$(nix store prefetch-file --json --unpack --name source \
  "$repo_url/archive/$rev.tar.gz" | jq -r '.hash')"

# `src` and `goose` both carry a `hash`, so nested attributes are set per block
set_top() {
  sed -i "s|^  $1 = \".*\";|  $1 = \"$2\";|" "$source_nix"
}
set_in() {
  sed -i "/^  $1 = /,/^  };/s|^    $2 = \".*\";|    $2 = \"$3\";|" "$source_nix"
}
set_src() { set_in src "$@"; }
set_goose() { set_in goose "$@"; }

set_top version "$latest"
set_top rev "$rev"
set_src hash "$src_hash"

src="$(nix eval --raw "$REPO_ROOT#buzz-app.src")"
goose_rev="$(jq -r '.revision' "$src/runtime/goose-acp.json")"
if [[ ! $goose_rev =~ ^[0-9a-f]{40}$ ]]; then
  echo "buzz-app: no goose revision in runtime/goose-acp.json" >&2
  exit 1
fi
if [[ $goose_rev != "$(sed -n '/^  goose = {/,/^  };/s/^    rev = "\(.*\)";/\1/p' "$source_nix")" ]]; then
  goose_hash="$(nix store prefetch-file --json --unpack --name source \
    "https://github.com/aaif-goose/goose/archive/$goose_rev.tar.gz" | jq -r '.hash')"
  set_goose rev "$goose_rev"
  set_goose hash "$goose_hash"
fi

# Fixed-output rebuild: plant a wrong hash, read the real one off the failure.
refresh_hash() {
  local setter="$1" name="$2" deps="$3" log
  "$setter" "$name" "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  log="$(nix build "$REPO_ROOT#$deps" --no-link 2>&1 || true)"
  if ! grep -q "got:" <<<"$log"; then
    echo "$log" >&2
    echo "$deps: failed to fetch" >&2
    exit 1
  fi
  "$setter" "$name" "$(grep -oP 'got:\s+\K\S+' <<<"$log" | tail -1)"
}

refresh_hash set_top cargoHash buzz-app.cargoDeps
refresh_hash set_top pnpmHash buzz-app.pnpmDeps
refresh_hash set_goose cargoHash buzz-app.goose-acp.cargoDeps

echo ":: buzz-app $current -> $latest"
