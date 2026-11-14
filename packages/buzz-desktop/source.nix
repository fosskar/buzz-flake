{ lib, fetchFromGitHub }:

# Single pinned upstream checkout shared by every buzz package. `version` is the
# desktop release version; the relay is cut from the same commit.
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

  # desktop/src-tauri/Cargo.lock, also vendored with fetchCargoVendor: the
  # outputHashes importCargoLock needs are keyed by git dependency names that
  # move with upstream, which the updater cannot track.
  desktopCargoHash = "sha256-NWtKer5P3o+csM+wsvSR2b8cZQFl78nldGEqHHqCGyU=";

  # pnpm store hashes for the two workspaces built from this checkout. They
  # follow the pin, so they live here rather than in the packages, where the
  # updater would not be allowed to rewrite them.
  desktopPnpmHash = "sha256-2tYG0tivzvVaFxdxCenzSxCui2sVA/HiSINyvQCCgwU=";
  webPnpmHash = "sha256-NazTNHuM4wJqnMHKJbviuIYW8o0YZND50DESrdQNsM4=";

  meta = {
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
