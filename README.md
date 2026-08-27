# buzz-flake

Nix packaging for [block/buzz](https://github.com/block/buzz): the desktop app,
the self-hosted relay and pairing servers, always-on community agents, and
NixOS, Home Manager, and Clan modules.

## Packages

| Attribute | Contents |
| --------------- | ----------------------------------------------------------------------------------------------------------- |
| `buzz-relay` | `buzz-relay` with `git` on `PATH` and the web bundles preconfigured, plus `buzz-admin` and `buzz-pair-relay` |
| `buzz-web` | The `web` and `admin-web` static bundles the relay serves |
| `buzz-sidecars` | `buzz-acp`, `buzz-agent`, `buzz-backend-kubernetes`, `buzz-dev-mcp`, `git-credential-nostr` and `buzz` |
| `buzz-desktop` | The Tauri desktop app, with the sidecar binaries bundled |

```console
nix run github:fosskar/buzz-flake#buzz-desktop
nix build github:fosskar/buzz-flake#buzz-relay
```

The desktop build enables the `mesh-llm` feature so **Settings → Compute** can
share local inference with relay members. Set the package argument
`withMeshLlm = false` to build the feature-off stubs instead. Its wrapper exposes
the GCC and Vulkan libraries required by Mesh-LLM's downloaded native runtime.

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
            pairingRelay = {
              enable = true;
              bindAddress = "127.0.0.1:5000";
            };
            members = {
              "<operator-pubkey>" = "admin";
              "<headless-agent-pubkey>" = "member";
            };
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
- **Pairing proxy route.** When `pairingRelay.enable = true`, route the advertised
  `pairingRelay.url` (by default `<relayUrl>/pair`) to
  `pairingRelay.bindAddress`. The sidecar holds pairing events only in memory.

`members` declaratively adds `member` or `admin` pubkeys after relay startup.
Reconciliation is additive and idempotent: users admitted through invite links
and manual `buzz-admin add-member` calls are never removed.

Settings without a dedicated option go through `services.buzz-server.settings`,
which is a plain map of environment variables:

```nix
services.buzz-server.settings = {
  BUZZ_REQUIRE_AUTH_TOKEN = true;
  RUST_LOG = "info";
};
```

## Home Manager community agents

`homeModules.buzz-agents` runs always-on `buzz-acp` harnesses as user services.
Each harness owns the relay connection, author gate, sessions, context, and
presence, and spawns `buzz-agent` as its ACP model process.

```nix
{
  imports = [ inputs.buzz-flake.homeModules.buzz-agents ];

  services.buzz-agents = {
    enable = true;
    relayUrl = "wss://buzz.example.com";
    ownerPubkey = "<operator-pubkey>";
    openrouterEnvironmentFile = "/run/secrets/openrouter.env";
    agents.orouter = {
      displayName = "ORouter";
      model = "deepseek/deepseek-v4-flash-0731";
      systemPrompt = "test agent";
      privateKeyFile = "/run/secrets/orouter.env";
      respondTo = "anyone";
    };
  };
}
```

The common environment file supplies `OPENROUTER_API_KEY`; each agent file
supplies `BUZZ_PRIVATE_KEY`. `respondTo = "anyone"` means every identity admitted
by a closed relay. Other modes are `owner-only`, `allowlist`, and `nobody`.

## Clan service

The flake exports `clan.modules.buzz`. The `server` role composes the
NixOS module and uses Clan vars to prompt for S3 credentials and generate stable
relay and git-hook secrets.

```nix
inputs.buzz-flake.url = "github:fosskar/buzz-flake";

inventory.instances.buzz = {
  module = {
    name = "buzz";
    input = "buzz-flake";
  };
  roles.server.machines.relay.settings = {
    relayUrl = "wss://buzz.example.com";
    s3.endpoint = "https://s3.example.com";
    pairingRelay.enable = true;
    members."<operator-pubkey>" = "admin";
  };
};
```

Run `clan vars generate relay` to enter the S3 access key and secret key. See
[`modules/buzz-clan.md`](modules/buzz-clan.md) for all role
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
whole flake; run it by hand with `./packages/buzz-desktop/update.sh`.

Two hashes it deliberately leaves alone, because neither can be derived on one
builder:

- `cargoOutputHashes` in `packages/buzz-desktop/source.nix` when a git
  dependency moves — the build fails loudly with the correct hash
- the `sherpa-onnx` archive version and hashes in
  `packages/buzz-desktop/package.nix` — the script refuses the bump when
  `sherpa-onnx-sys` moves in the lockfile
