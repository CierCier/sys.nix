{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    hyprland = {
		url = "github:hyprwm/Hyprland";
	};

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:ogulcancelik/herdr";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    tg = {
      url = "git+https://tangled.org/aly.codes/tg";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v1.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-unstable,
      hyprland,
      hyprland-plugins,
      noctalia,
      herdr,
      quickshell,
      tg,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.oilrig = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          inputs.lanzaboote.nixosModules.lanzaboote
          inputs.hyprland.nixosModules.default
          ./hosts/oilrig
          ({ pkgs, ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                llvmPackages_22 = nixpkgs-unstable.legacyPackages.${system}.llvmPackages_22;
              })
            ];
          })
        ];
      };
      # compat alias for /etc/nixos#nixos
      nixosConfigurations.nixos = self.nixosConfigurations.oilrig;
      formatter.${system} = nixpkgs.legacyPackages.${system}.nixfmt;
    };
}

