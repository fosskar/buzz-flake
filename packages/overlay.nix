final: _prev: {
  # One block/buzz pin for the relay, web bundles and sidecars.
  buzz-source = final.callPackage ./buzz-relay/source.nix { };
  buzz-web = final.callPackage ./buzz-web/package.nix { };
  buzz-relay = final.callPackage ./buzz-relay/package.nix { };
  buzz-sidecars = final.callPackage ./buzz-sidecars/package.nix { };
  # Buzz 1.0 lives in block/buzz-app, a separate repository with its own pin.
  buzz-app-source = final.callPackage ./buzz-app/source.nix { };
  buzz-app-goose-acp = final.callPackage ./buzz-app/goose-acp.nix { };
  buzz-app = final.callPackage ./buzz-app/package.nix { };
}
