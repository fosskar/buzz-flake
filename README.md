# buzz-flake

Nix packaging for [block/buzz](https://github.com/block/buzz): the desktop app,
the self-hosted relay server, and a NixOS module for the server.

Everything is built from one pinned upstream commit
(`packages/buzz-desktop/source.nix`),
currently the `desktop-v0.5.14` release.

## Packages

| Attribute | Contents |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| `buzz-relay` | `buzz-relay`, `buzz-admin` and `buzz-pair-relay`, wrapped with `git` on `PATH` and the web bundles preconfigured |
| `buzz-web` | The `web` and `admin-web` static bundles the relay serves |
| `buzz-sidecars` | `buzz-acp`, `buzz-agent`, `buzz-backend-kubernetes`, `buzz-dev-mcp`, `git-credential-nostr` and `buzz` |
| `buzz-desktop` | The Tauri desktop app, with the sidecar binaries bundled |

```console
nix run github:fosskar/buzz-flake#buzz-desktop
nix build github:fosskar/buzz-flake#buzz-relay
```

The desktop build fetches the prebuilt `sherpa-onnx` static library archive that
`sherpa-onnx-sys` would otherwise download from its build script; it is pinned by
hash and passed through `SHERPA_ONNX_ARCHIVE_DIR`.

## NixOS module

```nix
{
  inputs.buzz-flake.url = "github:fosskar/buzz-flake";

  outputs = { nixpkgs, buzz-flake, ... }: {
    nixosConfigurations.relay = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        buzz-flake.nixosModules.buzz-server
        {
          services.buzz-server = {
            enable = true;
            relayUrl = "wss://buzz.example.com";
            s3.endpoint = "https://s3.example.com";
            environmentFile = "/run/secrets/buzz-relay.env";
          };
        }
      ];
    };
  };
}
```

The module provisions a local PostgreSQL database and a dedicated Redis instance
by default (`database.createLocally`, `redis.createLocally`) and runs the
embedded migrations at startup (`autoMigrate`).

### Requirements the module does not provide

- **Object storage.** The relay stores media and durable git data in S3 and
  probes the bucket at startup; a failed probe is fatal. Point `s3.endpoint` at
  MinIO, Garage or a hosted bucket.
- **Secrets.** `environmentFile` must supply at least:
  - `BUZZ_RELAY_PRIVATE_KEY` — 64 hex characters, from `buzz-admin generate-key`.
    A stable value is required; without it the relay falls back to a well-known
    development key.
  - `BUZZ_GIT_HOOK_HMAC_SECRET` — at least 32 characters. Randomly regenerated
    on every start when unset.
  - `BUZZ_S3_ACCESS_KEY` and `BUZZ_S3_SECRET_KEY`.
- **TLS.** The relay speaks plain HTTP/WebSocket; put a reverse proxy in front
  of `bindAddress` and make `relayUrl` match the public URL, since it is used in
  the NIP-42 authentication challenge.

Settings without a dedicated option go through `services.buzz-server.settings`,
which is a plain map of environment variables:

```nix
services.buzz-server.settings = {
  BUZZ_REQUIRE_AUTH_TOKEN = true;
  RUST_LOG = "info";
};
```

## Clan service

The flake exports `clan.modules.buzz-server`. The `server` role composes the
NixOS module and uses Clan vars to prompt for S3 credentials and generate stable
relay and git-hook secrets.

```nix
inputs.buzz-flake.url = "github:fosskar/buzz-flake";

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

Run `clan vars generate relay` to enter the S3 access key and secret key. See
[`modules/buzz-server-clan.md`](modules/buzz-server-clan.md) for all role
settings.

## Development

```console
nix fmt                                    # treefmt: nixfmt, deadnix, statix, mdformat
nix flake check                            # formatting + NixOS module evaluation
```

## Updating

`packages/buzz-desktop/update.sh` moves the pin to the newest `desktop-v*`
release and refreshes the hashes that follow from it (`src`, both pnpm stores).
A nixbot schedule runs it through nixfiles' updater, which opens one PR for the
whole flake; run it by hand with `nix packages/buzz-desktop/update.sh`.

Two hashes it deliberately leaves alone, because neither can be derived on one
builder:

- `cargoOutputHashes` in `packages/buzz-desktop/source.nix` when a git
  dependency moves — the build fails loudly with the correct hash
- the `sherpa-onnx` archive version and hashes in
  `packages/buzz-desktop/package.nix` — the script refuses the bump when
  `sherpa-onnx-sys` moves in the lockfile

## License

The packaging in this repository is MIT-licensed. Buzz itself is Apache-2.0.
