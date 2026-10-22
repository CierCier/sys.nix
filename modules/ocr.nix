{ pkgs, ... }:

let
  python = pkgs.python3Packages;

  # The Python package, shared by the one-shot CLI and the warm daemon's
  # interpreter.
  indra-ocr-module = python.buildPythonPackage {
    pname = "indra-ocr";
    version = "0.3.2";
    pyproject = true;

    src = pkgs.fetchPypi {
      pname = "indra_ocr";
      version = "0.3.2";
      hash = "sha256-ZyljAFvm/pmGiJtI1FQKULpCQdqOYBz6RmUifLW/kfw=";
    };

    build-system = [ python.setuptools ];
    dependencies = with python; [
      numpy
      opencv-python-headless
      onnxruntime
      pypdfium2
      huggingface-hub
    ];

    nativeCheckInputs = with python; [
      pytestCheckHook
      pillow
      pikepdf
    ];
    pythonImportsCheck = [ "indra_ocr" ];
    meta.mainProgram = "indra-ocr";
  };

  indra-ocr = python.toPythonApplication indra-ocr-module;

  # Python with the package importable; the daemon and its client half run on
  # this interpreter.
  ocr-python = pkgs.python3.withPackages (_: [ indra-ocr-module ]);

  # The warm OCR service plus the client half (--request) that the Hyprland
  # helper calls.
  ocr-daemon = pkgs.writeShellScriptBin "ocr-daemon" ''
    export PYTHONNOUSERSITE=true
    exec ${ocr-python}/bin/python3 ${./ocr-daemon.py} "$@"
  '';
in
{
  environment.systemPackages = with pkgs; [
    indra-ocr
    ocr-daemon
    grimblast
    wl-clipboard
    libnotify
  ];

  # The screenshot helper uses this service while it is up and falls back to
  # the indra-ocr CLI when it is not, so Win+T works either way.
  systemd.user.services.ocr-daemon = {
    description = "Warm Indra OCR for the screenshot helper";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${ocr-daemon}/bin/ocr-daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
