{ config, pkgs, nix-colors, ...}:
let
  identity = if builtins.pathExists ./home-identity.nix
    then import ./home-identity.nix
    else { email = null; };
in
import ./home-common.nix {
  inherit config pkgs nix-colors;
  asciiArtFile = ./spw-ascii-art.txt;
  gitUserEmail = identity.email; # provided via untracked file
  includeCorporateCA = true;
  caCertPath = "/Users/chris.rowe/.certs/Cloud-Services-Root-CA.pem";
}
