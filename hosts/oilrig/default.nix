{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/desktop.nix
    ../../modules/theme.nix
    ../../modules/apps.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/gaming.nix
    ../../modules/audio.nix
    ../../modules/system.nix
  ];

  networking.hostName = "oilrig";
  system.stateVersion = "26.05";
}
