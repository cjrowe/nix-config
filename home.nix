{ config, pkgs, nix-colors, ...}:
import ./home-common.nix {
  inherit config pkgs nix-colors;
  asciiArtFile = ./spw-ascii-art.txt;
  gitUserEmail = "chris.rowe@spw.com";
  includeCorporateCA = true;
  caCertPath = "/Users/chris.rowe/.certs/Cloud-Services-Root-CA.pem";
}
