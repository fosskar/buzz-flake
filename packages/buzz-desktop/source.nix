{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
rec {
  version = "0.5.25";

  rev = "c8f73213089cbd5a0f1e675d3193558280d46e10";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-9WJ6q64x8rW6vPNi5qay9oHdPjaPMzmELLPF31aWBeM=";
  };

  # Root workspace Cargo.lock, vendored with fetchCargoVendor. importCargoLock
  # cannot handle this lock: it carries sqlx-core 0.9.0 twice (crates.io and
  # the launchbadge/sqlx fork pinned via [patch.crates-io]) and names vendor
  # directories by name-version only.
  cargoHash = "sha256-TOJmGcR2HHrO1MDLH4ALmETG1s07VN0ZLwJcSuJYLdY=";

  # desktop/src-tauri/Cargo.lock: output hash for its git dependency.
  desktopCargoOutputHashes = {
    "mesh-llm-sdk-0.76.2" = "sha256-xbyNjc2oInEkmQWkGDAslCM/cNhAVjE4xcpVLFixlLE=";
  };

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
