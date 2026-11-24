{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "1.0.7";

  rev = "ac0b9bbd619b73a08ca1e48d1af1ec588bf4f40b";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-9/4jOQEnt0LwNSheetgbjWu3LvlFvcTF390TLGB0fTQ=";
  };

  cargoHash = "sha256-o3Y6UfXt6Oxxd0D6dhXqP14A2gCog/3y5jjsWPyWHrI=";
  pnpmHash = "sha256-GjwpKrpvp25HrTeKb2uzKBFkT+A0TzwFpEjzlytw12I=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "fb55b5a6d7f5b5df96c8f817f1cde6a81880d9f1";
    hash = "sha256-gXk9tnTp9vfL1/9BEJ7TYBZdemAnoc039pMzabRqxhU=";
    cargoHash = "sha256-vqKRl4qxlHDEqe652BPtfnWvsee/X0rwaFcuY9AoA7Q=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
