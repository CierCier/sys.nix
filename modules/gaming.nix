{ pkgs, ... }:

{

  boot.kernelParams = [
    "split_lock_detect=off" # avoid split lock performance hit in games/Proton
    "nowatchdog"
  ];

  boot.kernel.sysctl = {
    "vm.max_map_count" = 2147483642;
    "vm.swappiness" = 10; # swap less aggressively with 16GB RAM
  };

  programs.gamemode = {
    enable = true;
    settings = {
      general = {
        renice = 10;
        desiredgov = "performance";
      };
      gpu = {
        apply_gpu_optimisations = "accept-responsibility";
        gpu_device = 1;
        nv_powermizer_mode = 1;
      };
    };
  };

  environment.systemPackages = with pkgs; [
    mangohud
    gamescope
    vulkan-tools
    mesa-demos
    libva-utils
    dxvk
    lutris
    wineWow64Packages.stable
    protonplus
    nvitop
    umu-launcher
    lsd
  ];

  systemd.tmpfiles.rules = [
    "d /etc/asusd 0755 root root -"
  ];

  services.asusd = {
    enable = true;
  };
  # ASUS GPU mux control (provides supergfxctl). Pairs with asusd;
  # replaces power-profiles-daemon for platform_profile ownership.
  # Mostly-plugged-in: `supergfxctl -m Hybrid` (iGPU daily, dGPU on demand
  # via offload) or `-m Dedicated` for max FPS at cost of power.
  services.supergfxd.enable = true;

}
