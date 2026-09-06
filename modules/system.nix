{
  config,
  pkgs,
  inputs,
  ...
}:

let
  compat = import ./compat.nix { inherit pkgs; };
in
{
  # Bootloader.
  boot.loader.systemd-boot = {
    enable = true;
    consoleMode = "max";
    configurationLimit = 15;
  };
  boot.loader.efi.canTouchEfiVariables = true;

  # Use latest kernel.
  boot.kernelPackages = pkgs.linuxPackages_zen;

  # Additional kernel modules for hardware support
  boot.kernelModules = [
    "i2c-dev"
    "asus-wmi-sensors"
    "intel_rapl_msr"
  ];

  # rtw89 driver quirks for RTL8852BE
  boot.extraModprobeConfig = ''
    options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y
    options rtw89_core disable_ps_mode=y
  '';

  # Hibernate support
  boot.resumeDevice = "/dev/disk/by-uuid/89475b0b-7721-473d-a985-66971b61de4d";

  systemd.sleep.settings = {
    Sleep = {
      HibernateDelaySec = "1800";
    };
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id == "org.freedesktop.login1.hibernate" ||
          action.id == "org.freedesktop.login1.hibernate-multiple-sessions" ||
          action.id == "org.freedesktop.login1.hibernate-ignore-inhibit") {
        return polkit.Result.YES;
      }
    });
  '';

  # Enable networking
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
    settings = {
      connectivity.interval = 0;
    };
  };

  networking.wireless.iwd = {
    enable = true;
    settings = {
      Network = {
        EnablePowerSave = false;
      };
      General = {
        RoamScanInterval = 0;
        RoamRetryInterval = 0;
      };
    };
  };

  services.resolved = {
    enable = true;
    settings.Resolve = {
      DNS = [
        "1.1.1.1#one.one.one.one"
        "8.8.8.8#dns.google"
      ];
      FallbackDNS = [
        "1.0.0.1#one.one.one.one"
      ];
      DNSSEC = "allow-downgrade";
      DNSOverTLS = "true";
      Domains = [ "~." ];
    };
  };
  # Set your time zone.
  time.timeZone = "Asia/Kolkata";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_TELEPHONE = "en_GB.UTF-8";
    LC_TIME = "en_GB.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.users."cier" = {
    isNormalUser = true;
    description = "cier";
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "keyd"
      "adbusers"
      "cups"
    ];
    shell = pkgs.fish;
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];
    auto-optimise-store = true;
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };
  # ESP32 / ttyACMx auto a+rw
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="tty", SUBSYSTEMS=="usb", ATTRS{idVendor}=="10c4|303a|1a86", MODE="0666"
  '';

  environment.systemPackages = with pkgs; [
    vim
    neovim
    wget
    git
    gh
    curl
    btop-cuda
    patchelf
    compat.ldconfig-wrapper
    keyd
	android-tools
	postgresql
	distrobox
  ];

  environment.sessionVariables = {
    EDITOR = "nvim";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_CACHE_HOME = "$HOME/.cache";
  };

  programs.fuse.enable = true;
  programs.xfconf.enable = true;

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  programs.coolercontrol.enable = true;
  services.openssh.enable = true;

  services.logind.settings = {
    Login = {
      HandleLidSwitch = "ignore";
      HandleLidSwitchExternalPower = "ignore";
      HandleLidSwitchDocked = "ignore";
      HandlePowerKey = "ignore";
    };
  };

  services.keyd = {
    enable = true;
    keyboards.default = {
      ids = [ "*" ];
      settings = {
        "main" = {
          "leftmeta+leftshift+f23" = "rightcontrol";
        };
      };
    };
  };

  services.cloudflare-warp.enable = true;

  services.tailscale.enable = true;
  virtualisation.docker.enable = true;
  virtualisation.waydroid.enable = true;

  services.printing = {
    enable = true;
    drivers = [
      pkgs.gutenprint
      pkgs.brlaser
      pkgs.brscan4
    ];
    openFirewall = true;
    defaultShared = true;
  };

  hardware.sane = {
    enable = true;
    extraBackends = [ pkgs.brscan4 ];
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    53317 # localsend
  ];
  networking.firewall.allowedUDPPorts = [
    53317 # localsend
  ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;


  # postgresql services
  services.postgresql.enable = true;

  programs.nix-ld.enable = true;
  systemd.tmpfiles.rules = [
    "L+ /lib/ld-musl-x86_64.so.1 - - - - ${pkgs.musl}/lib/ld-musl-x86_64.so.1"
  ];
  programs.nix-ld.libraries =
    (with pkgs; [
      stdenv.cc.cc.lib # libstdc++.so.6 (glibc)
      musl # libc.musl-x86_64.so.1
      zlib
      libffi
      libxml2
      openssl
      curl
      glib
      nss
      nspr
      expat
      fontconfig
      freetype
      libGL
      libGLU
      libdrm
      libxkbcommon
      wayland
      libx11
      libxext
      libxrandr
      libxcursor
      libxi
      libxinerama
      libxrender
      libxfixes
      libxdamage
      libxcomposite
      libxtst
      libxscrnsaver
      libxcb
      libxau
      libxdmcp
      pulseaudio
      alsa-lib
      sqlite
      icu
      icu78
      libgcc.lib
      libevdev
      udev
      vulkan-loader
      fuse
      libICE
      libSM
      gtk4
      gtk4-layer-shell
      libsoup_3
      json-glib
      libadwaita
      libxcrypt
      compat.libcrypt-compat
      libgbm
      atk
      at-spi2-core
      cairo
      cups
      gtk3
      pango
      dbus
      portaudio
    ])
    ++ [
      config.boot.kernelPackages.nvidiaPackages.stable
    ];

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };

  programs.nh = {
    enable = true;
    clean.enable = true;
    clean.extraArgs = "--keep-since 4d --keep 3";
    flake = "/etc/nixos";
  };

  nix.optimise = {
    automatic = true;
    dates = [ "03:00" ];
  };


  # Prevent Intel I2C controller (touchpad) from entering runtime suspend
  # Fixes "i2c_designware controller timed out" on ASUS Vivobook 16 V3607VU
  systemd.services.fix-touchpad-i2c = {
    description = "Prevent touchpad I2C controller from suspending";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-udev-settle.service" ];
    unitConfig.ConditionPathExists = "/sys/devices/pci0000:00/0000:00:19.0/i2c_designware.1/power/control";
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.bash}/bin/sh -c '${pkgs.coreutils}/bin/tee /sys/bus/pci/devices/0000:00:19.0/power/control /sys/devices/pci0000:00/0000:00:19.0/i2c_designware.1/power/control > /dev/null <<< on'";
    };
  };

}
