{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
rec {
  version = "0.5.28";

  rev = "f87c10895ea35a9a2cea629fef1d7532a3fecbc5";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-NEsLQwcoQ2zTgznFgGFGNgYPnoclicNVycSEjl7I0Wo=";
  };

  # Root workspace Cargo.lock, vendored with fetchCargoVendor. importCargoLock
  # cannot handle this lock: it carries sqlx-core 0.9.0 twice (crates.io and
  # the launchbadge/sqlx fork pinned via [patch.crates-io]) and names vendor
  # directories by name-version only.
  cargoHash = "sha256-UQ8qNqoeDwkwhmVZebi++gb2GP61dr1Zv2QU9mJ6KJ8=";

  # desktop/src-tauri/Cargo.lock, also vendored with fetchCargoVendor: the
  # outputHashes importCargoLock needs are keyed by git dependency names that
  # move with upstream, which the updater cannot track.
  desktopCargoHash = "sha256-lB+7VKXczOyJlr+6LP5UtyMKzyJCEXyBeFOi8Rznirw=";

  # pnpm store hashes for the two workspaces built from this checkout. They
  # follow the pin, so they live here rather than in the packages, where the
  # updater would not be allowed to rewrite them.
  desktopPnpmHash = "sha256-KEe9dxmIlwPeLpnTkrwJOd64gAGC/PxOBqMOVGbKyJs=";
  webPnpmHash = "sha256-cwAQL8d1CHcbRgnuUrSPt4Wux/fYsV2wnPjTbTotxCk=";

  meta = {
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
