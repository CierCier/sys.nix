{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # --- Quickshell Qt & KDE QML modules ---
    # (qt6.qt5compat, qt6.qtmultimedia already in modules/desktop.nix)
    qt6.qtpositioning # weather / location widget
    qt6.qtsensors # telemetry / hardware sensors
    kdePackages.syntax-highlighting # code formatting in AI chat sidebar
    kdePackages.kirigami.unwrapped # Fluent icon set, action center (unwrapped contains the QML module)

    # --- Shell CLI utilities ---
    libsecret # secret-tool for keyring storage
    libqalculate # qalc for launcher inline calculations
    cliphist # clipboard history (Super+V)
    cava # audio visualizer in top bar
    nodejs_22 # genius lyrics script
    translate-shell # translation widget (trans)
    hyprsunset # blue light / night filter
    swappy # screenshot annotation
    wf-recorder # screen recording
    tesseract # OCR & visual search
  ];

  fonts.packages = with pkgs; [
    # (material-symbols, nerd-fonts.jetbrains-mono already in modules/theme.nix)
    rubik # UI font
    readexpro # reading font
    # NOTE: space-grotesk not in nixpkgs 26.05 (only hanken-grotesk);
    # clock falls back to rubik until then
  ];
}
