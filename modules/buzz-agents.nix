self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.buzz-agents;
  agentType = lib.types.submodule (
    { name, ... }:
    {
      options = {
        enable = lib.mkEnableOption "the ${name} Buzz agent" // {
          default = true;
        };
        displayName = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        model = lib.mkOption {
          type = lib.types.str;
        };
        systemPrompt = lib.mkOption {
          type = lib.types.str;
        };
        privateKeyFile = lib.mkOption {
          type = lib.types.str;
          description = "Environment file containing BUZZ_PRIVATE_KEY.";
        };
        respondTo = lib.mkOption {
          type = lib.types.enum [
            "owner-only"
            "allowlist"
            "anyone"
            "nobody"
          ];
          default = "owner-only";
        };
        allowedUsers = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
        };
        parallelAgents = lib.mkOption {
          type = lib.types.ints.positive;
          default = 1;
        };
        environment = lib.mkOption {
          type = lib.types.attrsOf lib.types.str;
          default = { };
        };
      };
    }
  );

  mkService =
    name: agent:
    let
      agentEnvironment = {
        BUZZ_RELAY_URL = cfg.relayUrl;
        BUZZ_ACP_AGENT_COMMAND = lib.getExe' cfg.package "buzz-agent";
        BUZZ_ACP_AGENT_ARGS = "";
        BUZZ_ACP_AGENT_OWNER = cfg.ownerPubkey;
        BUZZ_ACP_RESPOND_TO = agent.respondTo;
        BUZZ_ACP_ALLOWED_RESPOND_TO = agent.respondTo;
        BUZZ_ACP_AGENTS = toString agent.parallelAgents;
        BUZZ_AGENT_PROVIDER = "openrouter";
        BUZZ_AGENT_MODEL = agent.model;
        BUZZ_AGENT_SYSTEM_PROMPT = agent.systemPrompt;
      }
      // lib.optionalAttrs (agent.allowedUsers != [ ]) {
        BUZZ_ACP_RESPOND_TO_ALLOWLIST = lib.concatStringsSep "," agent.allowedUsers;
      }
      // agent.environment;
      agentEnvironmentFile = pkgs.writeText "buzz-agent-${name}.env" (
        lib.concatStringsSep "\n" (
          lib.mapAttrsToList (key: value: "${key}=${lib.escapeShellArg value}") agentEnvironment
        )
        + "\n"
      );
      profile = pkgs.writeShellScript "buzz-agent-${name}-profile" ''
        exec ${lib.getExe' cfg.package "buzz"} users set-profile \
          --name ${lib.escapeShellArg agent.displayName} \
          --about ${lib.escapeShellArg agent.systemPrompt}
      '';
    in
    {
      Unit = {
        Description = "Buzz community agent ${agent.displayName}";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStartPre = toString profile;
        ExecStart = lib.getExe' cfg.package "buzz-acp";
        EnvironmentFile = [
          agentEnvironmentFile
          cfg.openrouterEnvironmentFile
          agent.privateKeyFile
        ];
        Restart = "always";
        RestartSec = 5;
        WorkingDirectory = "%S/buzz-agents/${name}";
        StateDirectory = "buzz-agents/${name}";
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
      Install.WantedBy = [ "default.target" ];
    };
in
{
  options.services.buzz-agents = {
    enable = lib.mkEnableOption "always-on Buzz community agents";
    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.buzz-sidecars;
      defaultText = lib.literalExpression "buzz-flake.packages.\${system}.buzz-sidecars";
    };
    relayUrl = lib.mkOption {
      type = lib.types.str;
    };
    ownerPubkey = lib.mkOption {
      type = lib.types.str;
    };
    openrouterEnvironmentFile = lib.mkOption {
      type = lib.types.str;
      description = "Environment file containing OPENROUTER_API_KEY.";
    };
    agents = lib.mkOption {
      type = lib.types.attrsOf agentType;
      default = { };
    };
  };

  config.systemd.user.services = lib.mkIf cfg.enable (
    lib.mapAttrs' (name: agent: lib.nameValuePair "buzz-agent-${name}" (mkService name agent)) (
      lib.filterAttrs (_: agent: agent.enable) cfg.agents
    )
  );
}
