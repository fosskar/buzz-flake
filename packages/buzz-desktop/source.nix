{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
rec {
  version = "0.5.17";

  rev = "c3bfd66947978fae93f4cfb46bea98ba20e32ccf";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-8RQfMHk2ZDRxFdRmOnAo8fhi8aBYESze2ECnx70OlNg=";
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
  desktopPnpmHash = "sha256-MbsnqmAmxTz6Ypr4BcJ6MPi2RSoTOsqFdNb4HFHrWPk=";
  webPnpmHash = "sha256-HyVZItaFVPy/gS8OS7EIUkDPgqots5KlHlqXXrjzv28=";

  meta = {
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
