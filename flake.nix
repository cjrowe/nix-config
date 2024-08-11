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
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Mac-bec3b07704d39abf
    darwinConfigurations."Mac-bec3b07704d39abf" = nix-darwin.lib.darwinSystem {

      specialArgs = { inherit nix-colors; };
      modules = [ 
        ./configuration.nix 
        home-manager.darwinModules.home-manager {
          home-manager.extraSpecialArgs = { inherit nix-colors; };

          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users."chris.rowe" = import ./home.nix;
        }
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."Mac-bec3b07704d39abf".pkgs;
  };
}
