{ config, pkgs, nix-colors, ...}:
import ./home-common.nix {
  inherit config pkgs nix-colors;
  gitUserEmail = "chris@rowe.cloud";
  includeCorporateCA = false;
}
