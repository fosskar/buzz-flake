final: _prev: {
  buzz-source = final.callPackage ./source.nix { };
  buzz-web = final.callPackage ./buzz-web.nix { };
  buzz-relay = final.callPackage ./buzz-relay.nix { };
  buzz-sidecars = final.callPackage ./buzz-sidecars.nix { };
  buzz-desktop = final.callPackage ./buzz-desktop.nix { };
}
