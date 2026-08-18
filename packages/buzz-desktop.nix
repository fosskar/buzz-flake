{
  lib,
  stdenv,
  rustPlatform,
  buzz-source,
  buzz-sidecars,
  fetchurl,
  cargo-tauri,
  nodejs_24,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  pkg-config,
  cmake,
  perl,
  wrapGAppsHook3,
  alsa-lib,
  glib-networking,
  gtk3,
  libayatana-appindicator,
  libsoup_3,
  openssl,
  webkitgtk_4_1,
  xdotool,
}:

let
  # sherpa-onnx-sys downloads a prebuilt static library archive from GitHub in
  # its build script. SHERPA_ONNX_ARCHIVE_DIR makes it use a local copy instead.
  sherpaVersion = "1.13.4";
  sherpaArchives = {
    x86_64-linux = {
      name = "sherpa-onnx-v${sherpaVersion}-linux-x64-static-lib.tar.bz2";
      hash = "sha256-mLDjGZZCb254JE284ZVVSPLGTo8BxL51uFr3zaoujVw=";
    };
    aarch64-linux = {
      name = "sherpa-onnx-v${sherpaVersion}-linux-aarch64-static-lib.tar.bz2";
      hash = "sha256-I7M2Fnh8yUnVsUOOl5RVD4BeIIoBTFwiRUgyB8WLvA8=";
    };
  };
  sherpaArchive =
    sherpaArchives.${stdenv.hostPlatform.system}
      or (throw "buzz-desktop: no sherpa-onnx prebuilt archive for ${stdenv.hostPlatform.system}");
  sherpaArchiveDir = fetchurl {
    inherit (sherpaArchive) name hash;
    url = "https://github.com/k2-fsa/sherpa-onnx/releases/download/v${sherpaVersion}/${sherpaArchive.name}";
    downloadToTemp = true;
    recursiveHash = true;
    postFetch = ''
      mkdir -p $out
      mv "$downloadedFile" "$out/${sherpaArchive.name}"
    '';
  };
in
rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz-desktop";
  inherit (buzz-source) version src;

  cargoRoot = "desktop/src-tauri";
  buildAndTestSubdir = "desktop/src-tauri";

  cargoLock = {
    lockFile = "${buzz-source.src}/desktop/src-tauri/Cargo.lock";
    outputHashes = buzz-source.cargoOutputHashes;
  };

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    pnpmWorkspaces = [ "buzz" ];
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  pnpmWorkspaces = [ "buzz" ];

  nativeBuildInputs = [
    cargo-tauri.hook
    rustPlatform.bindgenHook
    nodejs_24
    pnpm_11
    pnpmConfigHook
    pkg-config
    cmake
    perl
    wrapGAppsHook3
  ];

  buildInputs = [
    alsa-lib
    glib-networking
    gtk3
    libayatana-appindicator
    libsoup_3
    openssl
    webkitgtk_4_1
    xdotool
  ];

  dontUseCmakeConfigure = true;

  env = {
    SHERPA_ONNX_ARCHIVE_DIR = sherpaArchiveDir;
    # Several dependencies still ship pre-3.5 CMakeLists files.
    CMAKE_POLICY_VERSION_MINIMUM = "3.5";
  };

  # Tauri validates every `externalBin` entry at compile time, so the sidecars
  # must be in place with the host triple suffix before the bundle is built.
  preBuild = ''
    mkdir -p desktop/src-tauri/binaries
    for bin in ${lib.concatStringsSep " " buzz-sidecars.sidecarNames}; do
      install -m755 ${buzz-sidecars}/bin/$bin \
        desktop/src-tauri/binaries/$bin-${stdenv.hostPlatform.rust.rustcTarget}
    done
  '';

  doCheck = false;

  meta = buzz-source.meta // {
    description = "Buzz desktop app";
    mainProgram = "buzz-desktop";
  };
})
