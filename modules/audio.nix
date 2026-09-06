{ config, pkgs, ... }:

{
  # PipeWire audio server.
  # WirePlumber (session/policy manager) is enabled automatically:
  # services.pipewire.wireplumber.enable defaults to services.pipewire.enable.
  services.pipewire = {
    enable = true;

    # Compatibility layers — NOT enabled by default, must be explicit.
    alsa = {
      enable = true;
      support32Bit = true; # 32-bit ALSA for Wine/Proton games
    };
    pulse.enable = true; # PulseAudio API for desktop apps
    jack.enable = true; # JACK clients connect through PipeWire

    # Low-latency config for game audio
    extraConfig.pipewire."92-low-latency" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.quantum" = 256;
        "default.clock.min-quantum" = 64;
        "default.clock.max-quantum" = 2048;
      };
    };

    # Vault Ai22 USB interface: run playback at 24-bit, defaulting to 96 kHz.
    # Device-only rule, so the graph clock stays compliant; 44.1/48 kHz streams
    # pass through natively, anything else is resampled to the nearest allowed rate.
    wireplumber.extraConfig."91-vault-ai22" = {
      "monitor.alsa.rules" = [
        {
          matches = [
            { "device.name" = "~alsa_card.usb-Vault_Vault_Ai22-01"; }
          ];
          actions = {
            "update-props" = {
              "audio.format" = "S24_3LE";
              "audio.rate" = [ 96000 ];
              "audio.allowed-rates" = [ 44100 48000 96000 ];
            };
          };
        }
      ];
    };
  };

  # Real-time scheduling for audio (prevents crackles/dropouts)
  security.rtkit.enable = true;

  environment.systemPackages = with pkgs; [
    pavucontrol # audio mixer UI
    blueman # bluetooth manager
  ];

  # Bluetooth (primarily for audio devices)
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
