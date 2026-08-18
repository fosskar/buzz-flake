{
  rustPlatform,
  buzz-source,
  cmake,
  pkg-config,
  perl,
  openssl,
  protobuf,
}:

# The helper binaries the desktop app ships as Tauri sidecars, built from the
# root workspace (a different Cargo.lock than desktop/src-tauri).
rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "buzz-sidecars";
  inherit (buzz-source) version src;

  cargoLock = {
    lockFile = "${buzz-source.src}/Cargo.lock";
    outputHashes = buzz-source.cargoOutputHashes;
  };

  nativeBuildInputs = [
    cmake
    pkg-config
    perl
    protobuf
  ];

  buildInputs = [ openssl ];

  dontUseCmakeConfigure = true;

  cargoBuildFlags = [
    "--package=buzz-acp"
    "--package=buzz-agent"
    "--package=buzz-backend-kubernetes"
    "--package=buzz-dev-mcp"
    "--package=git-credential-nostr"
    "--package=buzz-cli"
  ];

  doCheck = false;

  passthru.sidecarNames = [
    "buzz-acp"
    "buzz-agent"
    "buzz-backend-kubernetes"
    "buzz-dev-mcp"
    "git-credential-nostr"
    "buzz"
  ];

  meta = buzz-source.meta // {
    description = "Sidecar binaries bundled with the Buzz desktop app";
  };
})
