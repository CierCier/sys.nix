{
  pkgs,
  inputs,
  ...
}:

{
  environment.systemPackages =
    (with pkgs; [
      sbctl
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
      scrcpy
      usbutils
      pciutils
      efibootmgr
      smartmontools
      hdparm
      dmidecode
      lshw
      virt-manager
      qemu_kvm

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
    ])
    ++ [
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.tg.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

  services.flatpak.enable = true;

}
