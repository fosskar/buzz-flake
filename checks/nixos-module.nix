self: system:

# Evaluation-only smoke test: build a machine that enables the module with the
# minimum required settings.
{
  imports = [ self.nixosModules.buzz-server ];

  boot.loader.grub.devices = [ "/dev/sda" ];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };

  services.buzz-server = {
    enable = true;
    relayUrl = "wss://buzz.example.com";
    s3.endpoint = "https://s3.example.com";
    environmentFile = "/run/secrets/buzz-relay.env";
  };

  system.stateVersion = "25.11";

  nixpkgs.hostPlatform = system;
}
