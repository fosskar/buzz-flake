{
  lib,
  rustPlatform,
  writeText,
  buzz-app-source,
  buzz-app-goose-acp,
  cargo-tauri,
  nodejs_24,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
  pkg-config,
  cmake,
  wrapGAppsHook3,
  dbus,
  glib-networking,
  gst_all_1,
  gtk3,
  libayatana-appindicator,
  libsoup_3,
  openssl,
  webkitgtk_4_1,
  # Community a fresh install opens with; vite embeds it at build time
  # (`BUZZ_DEFAULT_COMMUNITY_URL` in vite.config.ts), so setting it rebuilds.
  defaultCommunityUrl ? null,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "buzz-app";
  inherit (buzz-app-source) version src cargoHash;

  buildAndTestSubdir = "src-tauri";

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    hash = buzz-app-source.pnpmHash;
  };

  nativeBuildInputs = [
    cargo-tauri.hook
    nodejs_24
    pnpm_11
    pnpmConfigHook
    pkg-config
    cmake
    wrapGAppsHook3
  ];

  buildInputs = [
    dbus
    glib-networking
    # webkitgtk resolves its media pipeline through the plugin registry at
    # runtime; wrapGAppsHook3 turns these into GST_PLUGIN_SYSTEM_PATH_1_0.
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-libav
    gtk3
    libayatana-appindicator
    libsoup_3
    openssl
    webkitgtk_4_1
  ];

  dontUseCmakeConfigure = true;

  # The upstream beforeBuildCommand downloads a prebuilt goose-acp; the one
  # built from source is staged below instead. The version is what release.yml
  # injects.
  tauriBuildFlags = [
    "--config"
    (writeText "tauri.nix.conf.json" (
      builtins.toJSON {
        inherit (finalAttrs) version;
        build.beforeBuildCommand = "node scripts/build-agent-command.mjs && pnpm build";
      }
    ))
  ];

  env = {
    # What release.yml builds with; the frontend and buzzodz-plugins embed it.
    BUZZ_BUILDERLAB_URL = "https://app.builderlab.xyz";
  }
  // lib.optionalAttrs (defaultCommunityUrl != null) {
    BUZZ_DEFAULT_COMMUNITY_URL = defaultCommunityUrl;
  };

  # Tauri bundles src-tauri/resources/bin/ as the app's `bin` resources, where
  # host_process.rs resolves bundled programs.
  preBuild = ''
    install -Dm755 ${lib.getExe buzz-app-goose-acp} src-tauri/resources/bin/goose-acp
  '';

  doCheck = false;

  passthru.goose-acp = buzz-app-goose-acp;

  # The bundled entry ships an empty `Categories=`, as buzz-desktop's does.
  postInstall = ''
    substituteInPlace "$out/share/applications/Buzz Foundation.desktop" \
      --replace-fail 'Categories=' 'Categories=Network;InstantMessaging;Chat;'
  '';

  meta = buzz-app-source.meta // {
    description = "Buzz 1.0 desktop app (beta)";
    mainProgram = "Buzz";
  };
})
