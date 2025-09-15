{ config, pkgs, nix-colors, ...}:
let
  gitEmail = let v = builtins.getEnv "GIT_USER_EMAIL"; in if v == "" then null else v;
in import ./home-common.nix {
  inherit config pkgs nix-colors;
  gitUserEmail = gitEmail; # from environment only
  includeCorporateCA = false;
}
