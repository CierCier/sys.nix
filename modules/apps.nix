{
  config,
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
    chromium
	mpv
    imv
    obs-studio
    discord
    jq
    unzip
    p7zip
	rar
    localsend
    fzf
    ripgrep
    fd
    bat
	tree
	superfile
    zoxide
    rmpc
    matugen
    wallust
    tmux
    fastfetch
    zed-editor
    android-tools
    scrcpy
    usbutils
    pciutils
    efibootmgr
    smartmontools
    hdparm
    dmidecode
    lshw
    nvme-cli
    xarchiver

    sioyek
    qbittorrent

    ffmpeg
    (python3.withPackages (
      ps: with ps; [
        python-ffmpeg
        rich
		uv
      ]
    ))

	icu # needed for some libs
  ];

  services.flatpak.enable = true;

}
