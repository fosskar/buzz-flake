# Buzz server Clan service

The `server` role runs one self-hosted Buzz relay. It uses the NixOS module from
this flake and provisions local PostgreSQL and Redis instances by default.

## Inventory

Add `buzz-flake` as an input, then declare an instance:

```nix
inventory.instances.buzz = {
  module = {
    name = "buzz-server";
    input = "buzz-flake";
  };

  roles.server.machines.relay.settings = {
    relayUrl = "wss://buzz.example.com";
    s3.endpoint = "https://s3.example.com";
  };
};
```

Run `clan vars generate relay` to enter the S3 access key and secret key. The
service generator stores those credentials in a deployed environment file and
generates stable `BUZZ_RELAY_PRIVATE_KEY` and `BUZZ_GIT_HOOK_HMAC_SECRET`
values. Regenerating the vars replaces both generated secrets.

Object storage is mandatory. The relay probes the configured bucket at startup
and refuses to start when the probe fails. TLS and the public reverse proxy are
outside this service; `relayUrl` must match the public WebSocket URL used by
clients.

## `server` settings

- `relayUrl`: public WebSocket URL; required.
- `bindAddress`: API listen address. Defaults to `127.0.0.1:3000`.
- `adminHost`: bare authority that enables the admin UI. Defaults to `null`.
- `openFirewall`: open the API port. Defaults to `false`.
- `autoMigrate`: apply embedded PostgreSQL migrations at startup. Defaults to
  `true`.
- `database.createLocally`: provision local PostgreSQL. Defaults to `true`.
- `database.url`: PostgreSQL URL. Defaults to the local Unix socket.
- `redis.createLocally`: provision dedicated local Redis. Defaults to `true`.
- `redis.url`: Redis URL. Defaults to `redis://127.0.0.1:6380`.
- `s3.endpoint`: S3-compatible endpoint; required.
- `s3.bucket`: bucket name. Defaults to `buzz-media`.
- `s3.region`: region. Defaults to `us-east-1`.
- `s3.addressingStyle`: `path` or `virtual-host`. Defaults to `path`.
- `requireAuthToken`: require authentication tokens. Defaults to `false`.
- `requireRelayMembership`: require relay membership. Defaults to `false`.
