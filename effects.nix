# nixbot effects. The GitToken comes from nixbot at runtime (a github app
# installation token on github repos).
{ pkgs, nixbot }:
let
  inherit (nixbot.lib.effects { inherit pkgs; }) mkEffect;

  # nixbot mounts a pushable clone of the effect's commit at
  # $NIXBOT_EFFECT_CHECKOUT, which is also the working directory. The updaters
  # come from nixfiles, which needs no flake input to run.
  mkUpdateEffect =
    name: updater:
    mkEffect {
      name = "effect-${name}";
      checkout = true;
      inputs = [ pkgs.nix ];
      secretsMap.git.type = "GitToken";
      effectScript = ''
        nix --extra-experimental-features 'nix-command flakes' \
          run github:fosskar/nixfiles#updater-effect -- ${updater}
      '';
    };
in
_args: {
  onSchedule.update-flake-inputs = {
    when = {
      hour = 1;
      minute = 0;
    };
    outputs.effects.update-flake-inputs = mkUpdateEffect "update-flake-inputs" "flake-inputs";
  };

  # packages/buzz-desktop/update.sh moves the shared upstream pin, so this
  # opens one PR for the whole flake.
  onSchedule.update-pkgs = {
    when = {
      hour = 3;
      minute = 0;
    };
    outputs.effects.update-pkgs = mkUpdateEffect "update-pkgs" "packages";
  };
}
