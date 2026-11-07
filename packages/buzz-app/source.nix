{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. `version` is the newest `desktop-vX.Y.Z` tag; update.sh skips
# betas and the `v*-preview.N.M` prereleases cut from main.
rec {
  version = "0.7.16";

  rev = "b1e1cd82dd32e909aeb366fc587f0a50be1c2161";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-bLibxRzu1Oa5KKsbefem8aJzSILNbebPWFEYb8LWV7o=";
  };

  cargoHash = "sha256-NFzG5hBoKurZc0rJzVNq5uJ8fZwgFsZMznaIwT43HjA=";
  pnpmHash = "sha256-JCNK0Kwf80WFAVZxkiaM4Hs3mrZxP+PbiRYRXD+pV84=";

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
