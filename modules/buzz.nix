self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.buzz;
in
{
  options.programs.buzz = {
    enable = lib.mkEnableOption "the Buzz desktop app";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.buzz-app;
      defaultText = lib.literalExpression "buzz-flake.packages.\${system}.buzz-app";
      description = "The desktop app package to install.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
