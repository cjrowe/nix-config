{ pkgs, ... }: 
{
  nix.extraOptions = ''
    ssl-cert-file = /Users/chris.rowe/.certs/Cloud-Services-Root-CA.pem
    '';

  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages = with pkgs;
  [ 
    vim
    htop
    fastfetch
    bat
    awscli2
    fzf
    ripgrep
    fd
    jq
    cacert
    tldr
  ];

  fonts.packages = [
    pkgs.nerd-fonts.jetbrains-mono
  ];

  # Disable Nix management - handled by Determinate
  nix.enable = false;

  # nix.package = pkgs.nix;

  # Necessary for using flakes on this system.
  nix.settings.experimental-features = "nix-command flakes";

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;  # default shell on catalina
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  #system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  users.users."chris.rowe" = {
    name = "chris.rowe";
    home = "/Users/chris.rowe";
  };
  
  security.pam.services.sudo_local.touchIdAuth = true;
}
