{ lib, fetchFromGitHub }:

rec {
  version = "0.5.24-unstable-2026-09-23";
  rev = "ec7ea38f62ea917f15e85a678bc94f3bbee5bb64";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-swBon8daznDgTYK1PH7DoCW3/r4kJiD19/3stpZlRSQ=";
  };

  desktopCargoOutputHashes = {
    "mesh-llm-sdk-0.76.0-rc9" = "sha256-Lv0szQN+l5pxi8xjbt3v3iqaFN+eRTtNSeogP4JoCuc=";
  };
  cargoOutputHashes = desktopCargoOutputHashes // {
    "aws-creds-0.39.1" = "sha256-QAAm1phmeLFtDRgfDCoHijN1ce/rYzh18KziOUbL+hw=";
  };

  desktopPnpmHash = "sha256-KEe9dxmIlwPeLpnTkrwJOd64gAGC/PxOBqMOVGbKyJs=";
  webPnpmHash = "sha256-cwAQL8d1CHcbRgnuUrSPt4Wux/fYsV2wnPjTbTotxCk=";

  meta = {
    homepage = "https://github.com/block/buzz";
    license = lib.licenses.asl20;
    platforms = lib.platforms.linux;
  };
}
