{ config, pkgs, nix-colors, ...}:
let
  gitEmail = let v = builtins.getEnv "GIT_USER_EMAIL"; in if v == "" then null else v;
in import ./home-common.nix {
  inherit config pkgs nix-colors;
  asciiArtFile = ./spw-ascii-art.txt;
  # Git identity sourced exclusively from environment: GIT_USER_EMAIL
  gitUserEmail = gitEmail;
  includeCorporateCA = true;
  caCertPath = "/Users/chris.rowe/.certs/Cloud-Services-Root-CA.pem";
}
