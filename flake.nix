{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    hyprland.url = "github:hyprwm/Hyprland";

    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
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
      # add ?ref=<tag> to track a tag
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";

      # THIS IS IMPORTANT
      # Mismatched system dependencies will lead to crashes and other issues.
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
