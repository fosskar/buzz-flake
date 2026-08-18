{
  stdenvNoCC,
  buzz-source,
  nodejs_24,
  pnpm_11,
  fetchPnpmDeps,
  pnpmConfigHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "buzz-web";
  inherit (buzz-source) version src;

  nativeBuildInputs = [
    nodejs_24
    pnpm_11
    pnpmConfigHook
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_11;
    fetcherVersion = 4;
    pnpmWorkspaces = [
      "buzz-web"
      "buzz-admin-web"
    ];
    hash = "sha256-HyVZItaFVPy/gS8OS7EIUkDPgqots5KlHlqXXrjzv28=";
  };

  pnpmWorkspaces = [
    "buzz-web"
    "buzz-admin-web"
  ];

  buildPhase = ''
    runHook preBuild

    pnpm -C web build
    pnpm -C admin-web build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp -r web/dist $out/web
    cp -r admin-web/dist $out/admin-web

    runHook postInstall
  '';

  meta = buzz-source.meta // {
    description = "Static web and admin bundles served by the buzz relay";
  };
})
