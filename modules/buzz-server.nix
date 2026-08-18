self:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.buzz-server;

  # Every setting the relay reads is an environment variable; `settings` is the
  # escape hatch for the ones without a dedicated option.
  environment = lib.filterAttrs (_: v: v != null) (
    {
      BUZZ_BIND_ADDR = cfg.bindAddress;
      BUZZ_HEALTH_PORT = toString cfg.healthPort;
      BUZZ_METRICS_PORT = toString cfg.metricsPort;
      DATABASE_URL = cfg.databaseUrl;
      REDIS_URL = cfg.redisUrl;
      RELAY_URL = cfg.relayUrl;
      BUZZ_AUTO_MIGRATE = lib.boolToString cfg.autoMigrate;
      BUZZ_GIT_REPO_PATH = "${cfg.stateDir}/repos";
      BUZZ_S3_ENDPOINT = cfg.s3.endpoint;
      BUZZ_S3_BUCKET = cfg.s3.bucket;
      BUZZ_S3_REGION = cfg.s3.region;
      BUZZ_S3_ADDRESSING_STYLE = cfg.s3.addressingStyle;
      BUZZ_WEB_DIR = if cfg.serveWebUi then "${cfg.package.buzz-web}/web" else null;
      BUZZ_ADMIN_WEB_DIR = if cfg.adminHost == null then null else "${cfg.package.buzz-web}/admin-web";
      BUZZ_ADMIN_HOST = cfg.adminHost;
    }
    // lib.mapAttrs (_: toString) cfg.settings
  );

  bindPort = lib.toInt (lib.last (lib.splitString ":" cfg.bindAddress));
in
{
  options.services.buzz-server = {
    enable = lib.mkEnableOption "the Buzz relay server";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.stdenv.hostPlatform.system}.buzz-relay;
      defaultText = lib.literalExpression "buzz-flake.packages.\${system}.buzz-relay";
      description = "The `buzz-relay` package to run. Its `buzz-web` passthru provides the bundled UI.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "buzz";
      description = "User the relay runs as.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "buzz";
      description = "Group the relay runs as.";
    };

    stateDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/buzz";
      description = ''
        Directory for the relay's git working area. Durable git data lives in
        object storage; this path holds hydrated repositories and the pack cache.
      '';
    };

    bindAddress = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1:3000";
      description = "`BUZZ_BIND_ADDR`: address the WebSocket and REST API listen on.";
    };

    healthPort = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "`BUZZ_HEALTH_PORT`: port serving `/_liveness` and `/_readiness`.";
    };

    metricsPort = lib.mkOption {
      type = lib.types.port;
      default = 9102;
      description = "`BUZZ_METRICS_PORT`: port serving `/metrics`.";
    };

    relayUrl = lib.mkOption {
      type = lib.types.str;
      example = "wss://buzz.example.com";
      description = ''
        `RELAY_URL`: public WebSocket URL of this relay. Clients are challenged
        against this value during NIP-42 authentication, so it must match the
        URL they connect to.
      '';
    };

    adminHost = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "admin.buzz.example.com";
      description = ''
        `BUZZ_ADMIN_HOST`: bare authority (no scheme, path or `@`) that serves
        the admin UI. Admin routes stay disabled while this is null.
      '';
    };

    serveWebUi = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Serve the bundled web UI (`BUZZ_WEB_DIR`).";
    };

    autoMigrate = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        `BUZZ_AUTO_MIGRATE`: run the embedded database migrations at startup.
        With this disabled, run `buzz-admin migrate` before starting the relay.
      '';
    };

    databaseUrl = lib.mkOption {
      type = lib.types.str;
      default = "postgres:///buzz?host=/run/postgresql";
      description = ''
        `DATABASE_URL`. The default connects to a local PostgreSQL over its unix
        socket, which pairs with `database.createLocally`.
      '';
    };

    redisUrl = lib.mkOption {
      type = lib.types.str;
      default = "redis://127.0.0.1:${toString cfg.redis.port}";
      defaultText = lib.literalExpression ''"redis://127.0.0.1:''${toString cfg.redis.port}"'';
      description = "`REDIS_URL`. Redis is required; the relay aborts if it cannot connect.";
    };

    database.createLocally = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Provision a local PostgreSQL database and role named `buzz`.";
    };

    redis = {
      createLocally = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run a dedicated local Redis instance for the relay.";
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 6380;
        description = "Port of the local Redis instance.";
      };
    };

    s3 = {
      endpoint = lib.mkOption {
        type = lib.types.str;
        example = "https://s3.example.com";
        description = ''
          `BUZZ_S3_ENDPOINT`. Object storage holds media and durable git data;
          the relay probes it at startup and refuses to start if it is missing.
        '';
      };

      bucket = lib.mkOption {
        type = lib.types.str;
        default = "buzz-media";
        description = "`BUZZ_S3_BUCKET`.";
      };

      region = lib.mkOption {
        type = lib.types.str;
        default = "us-east-1";
        description = "`BUZZ_S3_REGION`.";
      };

      addressingStyle = lib.mkOption {
        type = lib.types.enum [
          "path"
          "virtual-host"
        ];
        default = "path";
        description = "`BUZZ_S3_ADDRESSING_STYLE`.";
      };
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      example = "/run/secrets/buzz-relay.env";
      description = ''
        Path to an `EnvironmentFile` holding the relay's secrets, kept out of
        the world-readable Nix store. Set at least `BUZZ_RELAY_PRIVATE_KEY`
        (64 hex characters, generated with `buzz-admin generate-key`),
        `BUZZ_GIT_HOOK_HMAC_SECRET`, `BUZZ_S3_ACCESS_KEY` and
        `BUZZ_S3_SECRET_KEY`.
      '';
    };

    settings = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.oneOf [
          lib.types.str
          lib.types.int
          lib.types.bool
        ]
      );
      default = { };
      example = {
        BUZZ_REQUIRE_AUTH_TOKEN = true;
        RUST_LOG = "info";
      };
      description = ''
        Extra environment variables for the relay. Values set here override the
        ones derived from the options above.
      '';
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Open the port from `bindAddress` in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.database.createLocally || cfg.user == "buzz";
        message = "services.buzz-server.database.createLocally provisions the role `buzz`, so services.buzz-server.user must stay \"buzz\".";
      }
    ];

    users.users.${cfg.user} = lib.mkIf (cfg.user == "buzz") {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.stateDir;
    };

    users.groups.${cfg.group} = lib.mkIf (cfg.group == "buzz") { };

    services.postgresql = lib.mkIf cfg.database.createLocally {
      enable = true;
      ensureDatabases = [ "buzz" ];
      ensureUsers = [
        {
          name = "buzz";
          ensureDBOwnership = true;
        }
      ];
    };

    services.redis.servers.buzz = lib.mkIf cfg.redis.createLocally {
      enable = true;
      bind = "127.0.0.1";
      inherit (cfg.redis) port;
    };

    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ bindPort ];

    systemd.services.buzz-relay = {
      description = "Buzz relay server";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network-online.target"
      ]
      ++ lib.optional cfg.database.createLocally "postgresql.target"
      ++ lib.optional cfg.redis.createLocally "redis-buzz.service";
      wants = [ "network-online.target" ];
      requires =
        lib.optional cfg.database.createLocally "postgresql.target"
        ++ lib.optional cfg.redis.createLocally "redis-buzz.service";

      inherit environment;

      serviceConfig = {
        ExecStart = lib.getExe cfg.package;
        User = cfg.user;
        Group = cfg.group;
        EnvironmentFile = lib.mkIf (cfg.environmentFile != null) cfg.environmentFile;
        StateDirectory = lib.mkIf (cfg.stateDir == "/var/lib/buzz") "buzz";
        WorkingDirectory = cfg.stateDir;
        Restart = "on-failure";
        RestartSec = 5;

        AmbientCapabilities = lib.mkIf (bindPort < 1024) [ "CAP_NET_BIND_SERVICE" ];
        CapabilityBoundingSet = lib.mkIf (bindPort >= 1024) [ "" ];
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        NoNewPrivileges = true;
        PrivateDevices = true;
        PrivateTmp = true;
        ProtectClock = true;
        ProtectControlGroups = true;
        ProtectHome = true;
        ProtectHostname = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        ProtectProc = "invisible";
        ProtectSystem = "strict";
        ReadWritePaths = [ cfg.stateDir ];
        RemoveIPC = true;
        RestrictAddressFamilies = [
          "AF_INET"
          "AF_INET6"
          "AF_UNIX"
        ];
        RestrictNamespaces = true;
        RestrictRealtime = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        SystemCallFilter = [
          "@system-service"
          "~@privileged"
        ];
        UMask = "0077";
      };
    };
  };
}
