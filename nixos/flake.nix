{
  description = "config";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";
    # use the following for unstable:
    # nixpkgs.url = "nixpkgs/nixos-unstable";
    # or any branch you want:
    # nixpkgs.url = "nixpkgs/{BRANCH-NAME}"
    # nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager"; # /release-23.05
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, ... }@inputs:
  let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
  in {
    nixosConfigurations = {
      nandi = lib.nixosSystem {
        specialArgs = {inherit inputs system;};
        modules = [ 
          ./configuration.nix
          inputs.home-manager.nixosModules.default
        ];
      };
    };
  };
}
