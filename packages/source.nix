{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
rec {
  version = "0.5.14";

  rev = "391495e7d347d20b67e39e3c240d17ef63c5c2c0";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-kiJqUSzQZw6i9+W62T2lFyiDFwOnOKGXIXvQj4oeQgE=";
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

  meta = {
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
