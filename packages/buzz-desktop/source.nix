{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
rec {
  version = "0.5.22";

  rev = "9ceb1f79bbc21785a0a075c40aecb3c058b1ea15";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-p4WLDBwiNiw1qlVo12Sz5js/r/6A3SiHBNCx8V9WlSs=";
  };

  # Output hashes for the git dependencies, keyed per git repository
  # (importCargoLock resolves them through the commit SHA). A hash without a
  # matching git dependency is an error, so the two lock files get separate sets.
  meshLlmOutputHash = {
    "mesh-llm-sdk-0.75.1" = "sha256-RXjmM66u40cxnacbvTtCFJShMK4BM+MHOyJ2vQ7Gw60=";
  };

  # Root workspace Cargo.lock.
  cargoOutputHashes = meshLlmOutputHash // {
    "aws-creds-0.39.1" = "sha256-QAAm1phmeLFtDRgfDCoHijN1ce/rYzh18KziOUbL+hw=";
  };

  # desktop/src-tauri/Cargo.lock.
  desktopCargoOutputHashes = meshLlmOutputHash;

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
