{
  config,
  pkgs,
  inputs,
  ...
}:

let
  rhine-labs-theme = pkgs.callPackage ./sddm-theme.nix { };
in
{
  environment.systemPackages =
    (with pkgs; [
      kitty
      grim
      slurp
      hyprlock
      hyprpicker
      brightnessctl
      playerctl
      clipse
      wl-clipboard
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
      thunar
      thunar-archive-plugin
      thunar-volman
      grimblast
      hyprlauncher
      wlogout
      dunst
      rofi
      nwg-look
      kdePackages.qt6ct
      rose-pine-hyprcursor
      polkit_gnome
      material-symbols

	  ntfs3g
      exfat
      dosfstools
      btrfs-progs

	  udiskie
      hypridle
      kdePackages.qtstyleplugin-kvantum
      fcitx5
      fcitx5-gtk
      kdePackages.fcitx5-qt
      uwsm
      qt6.qtwayland
      qt6.qtmultimedia
      qt6.qtbase
      qt6.qtsvg
      qt6.qtdeclarative
      qt6.qt5compat
      qt6.qtimageformats
      qt6.qtshadertools
      qt6.qttools
      kdePackages.qqc2-desktop-style
      fishPlugins.pure
      fishPlugins.async-prompt
      # hyprlandPlugins.csgo-vulkan-fix  # replaced by flake version below
      gtk4
      glib
	  portaudio
	  whitesur-gtk-theme
	  rose-pine-icon-theme
      appimage-run
    ])
    ++ [
      rhine-labs-theme
      # inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.csgo-vulkan-fix # disabled - see below
    ];

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.hyprland.enable = true;
  services.desktopManager.plasma6.enable = true;
  services.displayManager.defaultSession = "hyprland";
  # csgo-vulkan-fix disabled: upstream Hyprland git moved Window.hpp (hyprland/src/desktop/view/window/Window.hpp)
  # plugin built against flake hyprland fails until hyprland-plugins catches up
  # TODO: re-enable when hyprland-plugins updates
  # environment.etc."hypr/plugins/csgo-vulkan-fix.so".source =
  #   "${inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.csgo-vulkan-fix}/lib/libcsgo-vulkan-fix.so";

  services.upower.enable = true;
  services.power-profiles-daemon.enable = true;
  services.gnome.gnome-keyring.enable = true;

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "rhine-labs";
    extraPackages = [
      rhine-labs-theme
      pkgs.qt6.qtmultimedia
      pkgs.qt6.qt5compat
      pkgs.qt6.qtvirtualkeyboard
    ];
  };

  programs.fish.enable = true;

  services.udisks2.enable = true;

  systemd.user.services.polkit-gnome = {
    description = "PolicyKit GNOME Authentication Agent";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      Restart = "always";
      RestartSec = 3;
      TimeoutStopSec = 10;
    };
    environment = {
      GDK_BACKEND = "wayland";
      WAYLAND_DISPLAY = "wayland-1";
    };
  };

  systemd.user.services.udiskie = {
    description = "udiskie auto-mount";
    after = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.udiskie}/bin/udiskie --automount --notify";
      Restart = "on-failure";
    };
  };
}
