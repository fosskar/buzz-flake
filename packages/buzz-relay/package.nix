{
  lib,
  rustPlatform,
  buzz-source,
  buzz-web,
  cmake,
  pkg-config,
  perl,
  openssl,
  protobuf,
  git,
  makeWrapper,
}:

rustPlatform.buildRustPackage (_finalAttrs: {
  pname = "buzz-relay";
  inherit (buzz-source) version src;

  cargoLock = {
    lockFile = "${buzz-source.src}/Cargo.lock";
    outputHashes = buzz-source.cargoOutputHashes;
  };

  patches = [ ./retry-postgres-startup.patch ];

  nativeBuildInputs = [
    cmake
    pkg-config
    perl
    protobuf
    makeWrapper
  ];

  buildInputs = [ openssl ];

  # cmake is only used by dependency build scripts; the workspace itself is
  # plain cargo, so the cmake setup hook must not try to configure the source.
  dontUseCmakeConfigure = true;

  cargoBuildFlags = [
    "--package=buzz-relay"
    "--package=buzz-admin"
    "--package=buzz-pair-relay"
  ];

  # The workspace test suite needs a live Postgres, Redis and S3.
  doCheck = false;

  postInstall = ''
    wrapProgram $out/bin/buzz-relay \
      --prefix PATH : ${lib.makeBinPath [ git ]} \
      --set-default BUZZ_WEB_DIR ${buzz-web}/web \
      --set-default BUZZ_ADMIN_WEB_DIR ${buzz-web}/admin-web
  '';

  passthru = { inherit buzz-web; };

  meta = buzz-source.meta // {
    description = "Buzz relay server, admin CLI and pair relay";
    mainProgram = "buzz-relay";
  };
})
