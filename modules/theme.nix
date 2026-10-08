{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    adwaita-icon-theme
    rose-pine-cursor
  ];

  fonts = {
    enableDefaultPackages = true;
    packages = with pkgs; [
      inter
      noto-fonts
      noto-fonts-color-emoji
      nerd-fonts.jetbrains-mono
      jetbrains-mono
      material-symbols
      ibm-plex
    ];
  };

  environment.sessionVariables = {
    GTK_THEME = "Adwaita-dark";
    XCURSOR_THEME = "BreezeX-RosePine-Linux";
    XCURSOR_SIZE = "24";
  };
}
