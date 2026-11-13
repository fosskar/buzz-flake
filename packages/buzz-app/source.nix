{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "1.0.1";

  rev = "dfdb5582e6810e76681e24a33c3489ba2aa77e5c";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-Usjvb2l2qHM3N1FP3zfRUJV0ZG+1F6Q0C2jj0uJkBP8=";
  };

  cargoHash = "sha256-yYpqaWYUHZa61tdoyEU0P7OHbVrcR50X/PAA/+lHzBI=";
  pnpmHash = "sha256-Y1iFdum87ALHYnpHqkaCjPoNWx6K1u8a2BlUrZgtI4Y=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "5d03ef6ed07ba59826328f1aff18d9a754ff8ad2";
    hash = "sha256-0fAyv3ppEbe2Z2FAg8Y4NS4blEwpVbDd+Bz/ie1nwhk=";
    cargoHash = "sha256-L7SP+UuLpNAkC9hQigz8zHC9g/TrY183lpwy81V698I=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
