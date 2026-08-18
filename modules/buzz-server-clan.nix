self:
{ lib, ... }:
{
  _class = "clan.service";

  manifest = {
    name = "buzz-server";
    description = "run a self-hosted Buzz relay with PostgreSQL, Redis and S3";
    categories = [ "Web Services" ];
    readme = builtins.readFile ./buzz-server-clan.md;
  };

  roles.server = {
    description = "Buzz relay server";

    interface.options = {
      relayUrl = lib.mkOption {
        type = lib.types.str;
        example = "wss://buzz.example.com";
        description = "Public WebSocket URL used for NIP-42 authentication challenges.";
      };

      bindAddress = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1:3000";
        description = "Address the WebSocket and REST API listen on.";
      };

      adminHost = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "admin.buzz.example.com";
        description = "Bare authority that serves the admin UI.";
      };

      openFirewall = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Open the relay API port in the firewall.";
      };

      autoMigrate = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run embedded PostgreSQL migrations when the relay starts.";
      };

      database.createLocally = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Provision a local PostgreSQL database and role.";
      };

      database.url = lib.mkOption {
        type = lib.types.str;
        default = "postgres:///buzz?host=/run/postgresql";
        description = "PostgreSQL connection URL.";
      };

      redis.createLocally = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run a dedicated local Redis instance.";
      };

      redis.url = lib.mkOption {
        type = lib.types.str;
        default = "redis://127.0.0.1:6380";
        description = "Redis connection URL.";
      };

      s3.endpoint = lib.mkOption {
        type = lib.types.str;
        example = "https://s3.example.com";
        description = "S3-compatible endpoint for media and durable git data.";
      };

      s3.bucket = lib.mkOption {
        type = lib.types.str;
        default = "buzz-media";
        description = "S3 bucket name.";
      };

      s3.region = lib.mkOption {
        type = lib.types.str;
        default = "us-east-1";
        description = "S3 region.";
      };

      s3.addressingStyle = lib.mkOption {
        type = lib.types.enum [
          "path"
          "virtual-host"
        ];
        default = "path";
        description = "S3 addressing style.";
      };

      requireAuthToken = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require an authentication token (`BUZZ_REQUIRE_AUTH_TOKEN`).";
      };

      requireRelayMembership = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Require relay membership (`BUZZ_REQUIRE_RELAY_MEMBERSHIP`).";
      };
    };

    perInstance =
      {
        instanceName,
        settings,
        ...
      }:
      {
        nixosModule =
          {
            config,
            pkgs,
            ...
          }:
          let
            generatorName = "buzz-server-${instanceName}";
            generator = config.clan.core.vars.generators.${generatorName};
          in
          {
            imports = [ self.nixosModules.buzz-server ];

            clan.core.vars.generators.${generatorName} = {
              prompts = {
                s3-access-key = {
                  description = "S3 access key for the Buzz relay";
                  type = "hidden";
                  persist = true;
                };
                s3-secret-key = {
                  description = "S3 secret key for the Buzz relay";
                  type = "hidden";
                  persist = true;
                };
              };

              files.relay-environment = {
                secret = true;
                owner = "buzz";
                group = "buzz";
              };

              runtimeInputs = [
                self.packages.${pkgs.stdenv.hostPlatform.system}.buzz-relay
                pkgs.gnused
                pkgs.openssl
                pkgs.python3
              ];

              script = ''
                relay_private_key="$(${
                  lib.getExe' self.packages.${pkgs.stdenv.hostPlatform.system}.buzz-relay "buzz-admin"
                } generate-key | sed -n 's/^Secret key:  *//p')"
                test -n "$relay_private_key"
                git_hmac_secret="$(openssl rand -hex 32)"

                python3 - \
                  "$relay_private_key" \
                  "$git_hmac_secret" \
                  "$prompts/s3-access-key" \
                  "$prompts/s3-secret-key" \
                  "$out/relay-environment" <<'PY'
                import pathlib
                import shlex
                import sys

                private_key, hmac_secret, access_path, secret_path, output_path = sys.argv[1:]
                values = {
                    "BUZZ_RELAY_PRIVATE_KEY": private_key,
                    "BUZZ_GIT_HOOK_HMAC_SECRET": hmac_secret,
                    "BUZZ_S3_ACCESS_KEY": pathlib.Path(access_path).read_text().rstrip("\n"),
                    "BUZZ_S3_SECRET_KEY": pathlib.Path(secret_path).read_text().rstrip("\n"),
                }
                pathlib.Path(output_path).write_text(
                    "".join(f"{name}={shlex.quote(value)}\n" for name, value in values.items())
                )
                PY
              '';
            };

            services.buzz-server = {
              enable = true;
              inherit (settings)
                relayUrl
                bindAddress
                adminHost
                openFirewall
                autoMigrate
                ;
              databaseUrl = settings.database.url;
              redisUrl = settings.redis.url;
              database.createLocally = settings.database.createLocally;
              redis.createLocally = settings.redis.createLocally;
              inherit (settings) s3;
              environmentFile = generator.files.relay-environment.path;
              settings = {
                BUZZ_REQUIRE_AUTH_TOKEN = settings.requireAuthToken;
                BUZZ_REQUIRE_RELAY_MEMBERSHIP = settings.requireRelayMembership;
              };
            };
          };
      };
  };
}
