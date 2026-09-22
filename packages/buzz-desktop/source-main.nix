{ lib, fetchFromGitHub }:

rec {
  version = "0.5.23-unstable-2026-09-21";
  rev = "77729abfb692b25a0f4ec4a69add86af2e32c0dd";

  src = fetchFromGitHub {
    owner = "block";
    repo = "buzz";
    inherit rev;
    hash = "sha256-RNoSsS0eiFM3+EDcK+FVBEjiouL3kM1lRvZ1p222PZk=";
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
