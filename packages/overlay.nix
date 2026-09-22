final: _prev:
let
  main = final.lib.makeScope final.newScope (scope: {
    buzz-source = scope.callPackage ./buzz-desktop/source-main.nix { };
    buzz-web = scope.callPackage ./buzz-web/package.nix { };
    buzz-relay = scope.callPackage ./buzz-relay/package.nix { };
    buzz-sidecars = scope.callPackage ./buzz-sidecars/package.nix { };
    buzz-desktop = scope.callPackage ./buzz-desktop/package.nix { };
  });
in
{
  # The pin lives next to buzz-desktop because `version` is the desktop
  # release; the other packages are cut from the same commit.
  buzz-source = final.callPackage ./buzz-desktop/source.nix { };
  buzz-web = final.callPackage ./buzz-web/package.nix { };
  buzz-relay = final.callPackage ./buzz-relay/package.nix { };
  buzz-sidecars = final.callPackage ./buzz-sidecars/package.nix { };
  buzz-desktop = final.callPackage ./buzz-desktop/package.nix { };

  buzz-web-main = main.buzz-web;
  buzz-relay-main = main.buzz-relay;
  buzz-sidecars-main = main.buzz-sidecars;
  buzz-desktop-main = main.buzz-desktop;
}
