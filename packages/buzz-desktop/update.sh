#!/usr/bin/env nix
#!nix shell nixpkgs#bash nixpkgs#curl nixpkgs#gnused nixpkgs#gnugrep nixpkgs#nix nixpkgs#jq -c bash
# shellcheck shell=bash
#
# Moves the shared upstream pin to the newest `desktop-v*` release and
# refreshes the hashes that follow from it. Every package in this flake is cut
# from that one commit, so this is the only package updater the repo needs.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." &>/dev/null && pwd)"
source_nix="$SCRIPT_DIR/source.nix"

gh_token="${RENOVATE_GITHUB_COM_TOKEN:-${GITHUB_TOKEN:-}}"
api() { curl --fail -sS ${gh_token:+-u ":$gh_token"} "https://api.github.com/repos/block/buzz/$1"; }

tag="$(api "releases?per_page=50" | jq -r '[.[] | select(.draft | not) | .tag_name | select(startswith("desktop-v"))] | first')"
if [[ -z $tag || $tag == "null" ]]; then
  echo "could not determine the latest desktop-v* release" >&2
  exit 1
fi

latest="${tag#desktop-v}"
current="$(sed -n 's/^[[:space:]]*version = "\([^"]*\)";.*/\1/p' "$source_nix" | head -1)"
if [[ $current == "$latest" ]]; then
  echo ":: buzz already at $latest"
  exit 0
fi

ref="$(api "git/ref/tags/$tag")"
rev="$(jq -r '.object.sha' <<<"$ref")"
if [[ $(jq -r '.object.type' <<<"$ref") == "tag" ]]; then
  rev="$(api "git/tags/$rev" | jq -r '.object.sha')"
fi

src_hash="$(nix store prefetch-file --json --unpack --name source \
  "https://github.com/block/buzz/archive/$rev.tar.gz" | jq -r '.hash')"

sed -i \
  -e "s|^\([[:space:]]*\)version = \".*\";|\1version = \"$latest\";|" \
  -e "s|^\([[:space:]]*\)rev = \".*\";|\1rev = \"$rev\";|" \
  -e "s|^\([[:space:]]*\)hash = \".*\";|\1hash = \"$src_hash\";|" \
  "$source_nix"

src="$(nix eval --raw "$REPO_ROOT#buzz-desktop.src")"

# sherpa-onnx-sys downloads a prebuilt archive keyed by its own version, and
# the two per-platform hashes cannot be derived on one builder. Refuse the bump
# instead of leaving a pin that no longer matches the lockfile.
locked_sherpa="$(sed -n '/^name = "sherpa-onnx-sys"$/{n;s/^version = "\(.*\)"$/\1/p;}' \
  "$src/desktop/src-tauri/Cargo.lock")"
pinned_sherpa="$(sed -n 's/^[[:space:]]*sherpaVersion = "\(.*\)";.*/\1/p' "$SCRIPT_DIR/package.nix")"
if [[ $locked_sherpa != "$pinned_sherpa" ]]; then
  echo "buzz-desktop: sherpa-onnx moved $pinned_sherpa -> $locked_sherpa; update sherpaVersion and both archive hashes by hand" >&2
  exit 1
fi

# Fixed-output rebuild: plant a wrong hash, read the real one off the failure.
# Both pnpm hashes live in source.nix, the one file this updater owns.
refresh_pnpm_hash() {
  local attr="$1" old new log
  old="$(nix eval --raw "$REPO_ROOT#$attr.pnpmDeps.outputHash")"
  new="sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
  sed -i "s|$old|$new|" "$source_nix"
  log="$(nix build "$REPO_ROOT#$attr.pnpmDeps" --no-link 2>&1 || true)"
  if ! grep -q "got:" <<<"$log"; then
    sed -i "s|$new|$old|" "$source_nix"
    echo "$attr: pnpm deps failed to fetch" >&2
    exit 1
  fi
  sed -i "s|$new|$(grep -oP 'got:\s+\K\S+' <<<"$log" | tail -1)|" "$source_nix"
}

refresh_pnpm_hash buzz-desktop
refresh_pnpm_hash buzz-web

echo ":: buzz $current -> $latest"
