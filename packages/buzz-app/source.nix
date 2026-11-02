{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "0.7.5";

  rev = "7878f060916d3663d5ced3f8f464cd295685cc34";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-FWftGz5HINCdzDVe7ufXc6SiYN8QtzzwdxtRgmqAe2w=";
  };

  cargoHash = "sha256-U6lImiMmyLKfT3pR0AEaZFPUtzCLft3M/b57eAboI28=";
  pnpmHash = "sha256-J+1ZWbbgM0QZnHcoqFBfcXqJcqAxR760qhYKkJMTC/k=";

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
