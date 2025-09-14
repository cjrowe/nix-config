{ pkgs, ... }:
{
  #########################
  # Nix & Package Settings
  #########################
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nixpkgs.config.allowUnfree = true;

  #########################
  # Host Identity / Locale
  #########################
  networking.hostName = "desktop-personal";
  time.timeZone = "UTC"; # Adjust if you prefer a local TZ, e.g. "Europe/London"
  i18n.defaultLocale = "en_US.UTF-8";
  console.keyMap = "us";

  #########################
  # Users
  #########################
  users.users.chris = {
    isNormalUser = true;
    description = "Chris Rowe";
    extraGroups = [ "wheel" "networkmanager" ];
    shell = pkgs.zsh;
  };
  programs.zsh.enable = true;
  security.sudo.wheelNeedsPassword = false; # Convenient inside WSL; tighten if desired

  #########################
  # WSL Specific Hardening / QoL
  #########################
  # Limit unnecessary background services typical on full NixOS installs.
  services.openssh.enable = false; # Enable only if you need inbound SSH.
  services.cron.enable = false;
  services.avahi.enable = false;

  # Provide a minimal /etc/wsl.conf to avoid Windows PATH pollution and set default user.
  environment.etc."wsl.conf".text = ''
    [user]
    default=chris
    [interop]
    enabled=true
    appendWindowsPath=false
  '';

  # Optional: speed up shell startup by trimming systemd units (WSL often doesn't use many).
  systemd.enableEmergencyMode = false;

  #########################
  # Packages
  #########################
  environment.systemPackages = with pkgs; [
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
    zsh
  ];

  # You can expand with WSL-specific integration tools later if needed.

  #########################
  # System Version Pin
  #########################
  system.stateVersion = "24.05"; # Do not change on existing installs without reading docs
}
