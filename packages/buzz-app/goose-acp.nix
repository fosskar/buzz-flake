{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  buzz-app-source,
  cmake,
  pkg-config,
  protobuf,
  dbus,
  libxcb,
  openssl,
}:

# goose-acp as scripts/build-goose-acp.mjs builds it from runtime/goose-acp.json:
# the goose pin, `--profile lean --no-default-features --features <pin>`.
rustPlatform.buildRustPackage {
  pname = "buzz-app-goose-acp";
  version = "0-unstable-${builtins.substring 0 9 buzz-app-source.goose.rev}";

  src = fetchFromGitHub {
    owner = "aaif-goose";
    repo = "goose";
    inherit (buzz-app-source.goose) rev hash;
  };

  inherit (buzz-app-source.goose) cargoHash;

  buildType = "lean";
  buildNoDefaultFeatures = true;
  buildFeatures = [
    "rustls-tls"
    "system-keyring"
    "online-model-meta"
  ];
  cargoBuildFlags = [
    "--package=goose"
    "--bin=goose-acp"
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
    protobuf
    rustPlatform.bindgenHook
  ];

  buildInputs = [
    dbus
    openssl
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ libxcb ];

  dontUseCmakeConfigure = true;

  doCheck = false;

  meta = buzz-app-source.meta // {
    description = "goose ACP agent bundled with the Buzz 1.0 desktop app";
    homepage = "https://github.com/aaif-goose/goose";
    mainProgram = "goose-acp";
  };
}
