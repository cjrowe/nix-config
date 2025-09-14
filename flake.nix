{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-colors.url = "github:misterio77/nix-colors";
  };

  outputs = { self, nix-darwin, nixpkgs, home-manager, nix-colors, ... }@inputs:
  {
    # Build Darwin configs using:
    # $ darwin-rebuild switch --flake .#macbook-spw
    # $ darwin-rebuild switch --flake .#macbook-personal

    ##############################
    # Work Mac (renamed)
    ##############################
    darwinConfigurations."macbook-spw" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit nix-colors; };
      modules = [
        ./configuration.nix
        home-manager.darwinModules.home-manager {
          home-manager.extraSpecialArgs = { inherit nix-colors; };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."chris.rowe" = import ./home.nix; # Work profile
        }
      ];
    };

    ##############################
    # Personal Mac
    ##############################
    darwinConfigurations."macbook-personal" = nix-darwin.lib.darwinSystem {
      specialArgs = { inherit nix-colors; };
      modules = [
        ./configuration.nix
        # Override / extend any Darwin-specific settings if needed later via an inline module
        ({ config, ... }: {
          # Different hostname (optional if you want distinct network name)
          networking.hostName = "macbook-personal";
        })
        home-manager.darwinModules.home-manager {
          home-manager.extraSpecialArgs = { inherit nix-colors; };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."chris.rowe" = import ./home-personal.nix; # Personal profile
        }
      ];
    };

    ##############################
    # Personal WSL (NixOS) Desktop
    ##############################
    nixosConfigurations."desktop-personal" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux"; # WSL / desktop architecture assumption
      specialArgs = { inherit nix-colors; };
      modules = [
        ./nixos/desktop-personal.nix
        home-manager.nixosModules.home-manager {
          home-manager.extraSpecialArgs = { inherit nix-colors; };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."chris" = import ./home-personal.nix; # Use same personal profile (Linux compatible)
        }
      ];
    };

    # Convenience: package set for primary (work) Mac config
    darwinPackages = self.darwinConfigurations."macbook-spw".pkgs;
  };
}
