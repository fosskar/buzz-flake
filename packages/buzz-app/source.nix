{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "1.0.6";

  rev = "be9373d0ad838b05cf3d89020de27bfedea7dec9";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-RsvYf36f2Wl0f870BWHNVTekZ8NJdFaBuQc0XdEHmcI=";
  };

  cargoHash = "sha256-AzEK0VW01dwt7tu7MjGIg7gITV7++yJhcPlcRNWJoYY=";
  pnpmHash = "sha256-GjwpKrpvp25HrTeKb2uzKBFkT+A0TzwFpEjzlytw12I=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "b4e789ef5fd0243415243d7dfd9113c91b517c3c";
    hash = "sha256-SWYsiTgkdF0V/nx3nMrKvMCcra1w2QbTYUsxfeVlNqc=";
    cargoHash = "sha256-p9YR4HwHUbtSRSWKcxvfj+1NrpbKPXwAf+djsrRGWFs=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
