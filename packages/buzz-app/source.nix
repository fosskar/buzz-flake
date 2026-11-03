{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "0.7.7";

  rev = "2da58c2b3b9a2a52bac9c7fab82f40b1d464e5b2";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-buzb1KxpBOI5hmcRdbmpNVNS9HA0fxEaUD6W89RD2Z4=";
  };

  cargoHash = "sha256-HtPOGbbY/QZfSEeg96pNh1FOTv+/VR/esCbF2G8Ml90=";
  pnpmHash = "sha256-6XU133FO7eoAIDPvq823RnCBvpuvzZr6oSU3O/3CiV0=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "30bba95105e59bc3e7df624cf6b4d433690cfe12";
    hash = "sha256-hFW9gcuYFyyXOU/tB2v5WVNlX9arMG0Qs5qMb+KRmqw=";
    cargoHash = "sha256-jVgT8mYFX0KHjcpmK6TbshElXkLpNKgZoZz1JXXi0mk=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
