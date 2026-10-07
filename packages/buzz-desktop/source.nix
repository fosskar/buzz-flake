{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
rec {
  version = "0.5.27";

  rev = "7a2fb3cc2d401e91e67d9819741d9025278cbec0";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-h/4xEemRexKpjz4ZD9XKGSL+0vizdx5QuqmVO3oO7W4=";
  };

  # Root workspace Cargo.lock, vendored with fetchCargoVendor. importCargoLock
  # cannot handle this lock: it carries sqlx-core 0.9.0 twice (crates.io and
  # the launchbadge/sqlx fork pinned via [patch.crates-io]) and names vendor
  # directories by name-version only.
  cargoHash = "sha256-e2vWeSx9JTjHqupOMkNpD+0vNCs8ubMm/lRp+RVRK78=";

  # desktop/src-tauri/Cargo.lock, also vendored with fetchCargoVendor: the
  # outputHashes importCargoLock needs are keyed by git dependency names that
  # move with upstream, which the updater cannot track.
  desktopCargoHash = "sha256-oPJNW3eQfZc1oIYWNmAqpc7/F6NnMePbfQBG/kMQ1UU=";

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
