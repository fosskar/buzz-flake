{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "1.0.3";

  rev = "e69b6f9eecf94988034b4d8d5ad78209ed627208";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-p/E2wtNvWYN+QKNVlooYEmeAt//+W0d1oGg26rK6PyU=";
  };

  cargoHash = "sha256-yYpqaWYUHZa61tdoyEU0P7OHbVrcR50X/PAA/+lHzBI=";
  pnpmHash = "sha256-hTPwJ69mfaZ27ASZw7gF8LiS7Gpy7D1hv8Jg3DbNIdY=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "e62a656f460d6399b34c747014d810727ff70b05";
    hash = "sha256-GmL5+YRVZarlDRqewIeWB8mcVdpOKRsVwUEankgZXgY=";
    cargoHash = "sha256-GM+FGE7g3gA8ZP//CDrVYAq4C39AOFcLz+baOQv/Qv0=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
