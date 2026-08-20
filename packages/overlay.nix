final: _prev: {
  # The pin lives next to buzz-desktop because `version` is the desktop
  # release; the other packages are cut from the same commit.
  buzz-source = final.callPackage ./buzz-desktop/source.nix { };
  buzz-web = final.callPackage ./buzz-web/package.nix { };
  buzz-relay = final.callPackage ./buzz-relay/package.nix { };
  buzz-sidecars = final.callPackage ./buzz-sidecars/package.nix { };
  buzz-desktop = final.callPackage ./buzz-desktop/package.nix { };
}
