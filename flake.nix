{
  description = "Nix packaging for block/buzz: desktop app, relay server, and a NixOS module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
      treefmtFor = forAllSystems (pkgs: treefmt-nix.lib.evalModule pkgs ./treefmt.nix);
    in
    {
      overlays.default = import ./packages/overlay.nix;

      packages = forAllSystems (
        pkgs:
        let
          scope = pkgs.extend self.overlays.default;
        in
        {
          inherit (scope)
            buzz-source
            buzz-web
            buzz-relay
            buzz-sidecars
            buzz-desktop
            ;
          default = scope.buzz-relay;
        }
      );

      nixosModules = {
        buzz-server = import ./modules/buzz-server.nix self;
        default = self.nixosModules.buzz-server;
      };

      checks = forAllSystems (pkgs: {
        formatting = treefmtFor.${pkgs.stdenv.hostPlatform.system}.config.build.check self;

        nixos-module =
          (nixpkgs.lib.nixosSystem {
            modules = [ (import ./checks/nixos-module.nix self pkgs.stdenv.hostPlatform.system) ];
          }).config.system.build.toplevel;
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = [
            pkgs.nix-prefetch-git
            treefmtFor.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
          ];
        };
      });

      formatter = forAllSystems (
        pkgs: treefmtFor.${pkgs.stdenv.hostPlatform.system}.config.build.wrapper
      );
    };
}
