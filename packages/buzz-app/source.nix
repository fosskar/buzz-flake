{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "0.7.8";

  rev = "48bea39c89249917574dad33663a1039dc7f5cf5";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-L6IRSa5prmUHOdClfYBLYG1c+paKXZEd4woD5tW9hsk=";
  };

  cargoHash = "sha256-R81qkDLinyMMhvthgiiMukBd3oaJ6QKU8d7r8YTTKEA=";
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
