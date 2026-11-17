{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "1.0.4";

  rev = "a1c9c96940d2a6c81fce9beed9b7cbcc34b144b8";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-da336y05Fpe1NgE0rbcHHSIFsH8EEcdBCQzrAn+34rU=";
  };

  cargoHash = "sha256-cCkzcprPM1OFu521KQdxc0+puxuOeoD3CMXb3dahQWE=";
  pnpmHash = "sha256-Dur+QkaPDfSR4VejxN0si0Rxtt1b+/yeYj1ibdqdRAY=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "9da692fde8ac69ec385b5e7d68b92cc7101a509a";
    hash = "sha256-CacWGZMgmV1K2/FImZCVP3bs9svK8DVaU9nekm7VEg4=";
    cargoHash = "sha256-DdSR+Iy4DodOREvnZfB6+F5WYv7FLv8IdZom215Tmco=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
