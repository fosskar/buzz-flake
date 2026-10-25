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

    app = lib.mkOption {
      type = lib.types.enum [
        "buzz-desktop"
        "buzz-app"
      ];
      default = "buzz-desktop";
      description = ''
        Which desktop app to install: `buzz-desktop` is Buzz 0.X from
        block/buzz, `buzz-app` is the Buzz 1.0 beta from block/buzz-app.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.${cfg.app};
      defaultText = lib.literalExpression "buzz-flake.packages.\${system}.\${config.programs.buzz.app}";
      description = "The desktop app package to install. Defaults to the package named by `app`.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
  };
}
