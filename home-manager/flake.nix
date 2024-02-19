{
  description = "config flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-23.11";

    home-manager = {
      url = "github:nix-community/home-manager/release-23.11";  
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
  let
    lib = nixpkgs.lib;
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    nixosConfigurations = {
      nandi = lib.nixosSystem {
        inherit system;
        modules = [ ./configuration.nix ];
        # specialArgs = {inherit inputs system;}; # alternative to the above
        # modules = [ 
        #   ./configuration.nix
        #   inputs.home-manager.nixosModules.default
        # ];
      };
    };
    homeConfigurations = {
      benjamin = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [ ./home.nix ];
      };
    };
  };
}
