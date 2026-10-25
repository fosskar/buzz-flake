# Buzz Clan service

The `server` role runs one self-hosted Buzz relay. It uses the NixOS module from
this flake and provisions local PostgreSQL and Redis instances by default.

## Inventory

Add `buzz-flake` as an input, then declare an instance:

```nix
inventory.instances.buzz = {
  module = {
    name = "buzz";
    input = "buzz-flake";
  };

  roles.server.machines.relay.settings = {
    relayUrl = "wss://buzz.example.com";
    s3.endpoint = "https://s3.example.com";
  };

  roles.client.tags = [ "workstation" ];
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

## `client` role

Installs a desktop app pointed at the server's `relayUrl`. The role expects
exactly one server machine. Identity keys are not managed: they are created in
the app and stored in the user's keyring.

- `app`: `buzz-desktop` (Buzz 0.X) or `buzz-app` (Buzz 1.0 beta). Defaults to
  `buzz-desktop`.

`buzz-desktop` gets `BUZZ_RELAY_URL` through a wrapper, so the app offers this
instance's relay instead of the upstream default; a user-set `BUZZ_RELAY_URL`
still wins. `buzz-app` has no runtime override: the relay is embedded at build
time as the community a fresh install opens with, so the client machines build
that variant from source instead of using a cached `buzz-app`.
