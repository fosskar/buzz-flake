{ lib, fetchFromGitHub }:

# Pinned block/buzz-app checkout plus the goose revision it bundles as
# goose-acp. Upstream only publishes `v0.0.0-preview.N.M` prereleases cut from
# main, so `version` is the preview number of the pinned release.
rec {
  version = "0.0.0-preview.166.1";

  rev = "11386c508611acd6ceb19ccfc748365bf42466a8";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz-app";
    inherit rev;
    hash = "sha256-dR89XGAiQP8HoiKjsByb4rAhlwY/i86f4XZyPPc0smo=";
  };

  cargoHash = "sha256-n520zYtBxJQdEP8eBmH3ZjMi/YHnjHyiZ5wx5NlGkXQ=";
  pnpmHash = "sha256-VnxI+dQkYdwogfn7/AZAtUo/xA0xhldcn4GHTmLl6RI=";

  # runtime/goose-acp.json in the pinned checkout
  goose = {
    rev = "122834086b62ae39adf721de32ae59fcde904a8c";
    hash = "sha256-77LzSliHMESH4ugC5htM1SZcrNl6Oot1ZdDNjK8P2LE=";
    cargoHash = "sha256-DeSArRlTkWYNzcPr7iCpV1S+6V3uiEcIfKHT7ipk/O4=";
  };

  meta = {
    homepage = "https://github.com/block/buzz-app";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
