final: _prev: {
  # The pin lives next to buzz-desktop because `version` is the desktop
  # release; the other packages are cut from the same commit.
  buzz-source = final.callPackage ./buzz-desktop/source.nix { };
  buzz-web = final.callPackage ./buzz-web/package.nix { };
  buzz-relay = final.callPackage ./buzz-relay/package.nix { };
  buzz-sidecars = final.callPackage ./buzz-sidecars/package.nix { };
  buzz-desktop = final.callPackage ./buzz-desktop/package.nix { };
  # Buzz 1.0 lives in block/buzz-app, a separate repository with its own pin.
  buzz-app-source = final.callPackage ./buzz-app/source.nix { };
  buzz-app-goose-acp = final.callPackage ./buzz-app/goose-acp.nix { };
  buzz-app = final.callPackage ./buzz-app/package.nix { };
}
