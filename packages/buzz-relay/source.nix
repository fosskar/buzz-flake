{ lib, fetchFromGitHub }:

# Single pinned block/buzz checkout shared by every package except buzz-app.
# `version` is the newest `desktop-v*` release; the relay is cut from that commit.
rec {
  version = "0.5.30";

  rev = "dece76e7e28875b0fd24875fcb802150ef1abec0";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-Ay6zUeHHYO92/Fs4FGHm1+QQUoUEQjYyOC3dDg5+7Ss=";
  };

  # Root workspace Cargo.lock, vendored with fetchCargoVendor. importCargoLock
  # cannot handle this lock: it carries sqlx-core 0.9.0 twice (crates.io and
  # the launchbadge/sqlx fork pinned via [patch.crates-io]) and names vendor
  # directories by name-version only.
  cargoHash = "sha256-pYCis8LXLUKU3iPaUkeR/hH3XmBljCjVZQ7EDD2cqrs=";

  # pnpm store hash for the web workspace. It follows the pin, so it lives here
  # rather than in buzz-web, where the updater would not be allowed to rewrite it.
  webPnpmHash = "sha256-NazTNHuM4wJqnMHKJbviuIYW8o0YZND50DESrdQNsM4=";

  meta = {
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
