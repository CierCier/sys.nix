{ stdenv }:

stdenv.mkDerivation {
  pname = "sddm-rhine-labs";
  version = "1.0";

  src = builtins.path {
    path = ./sddm-rhine-labs;
    name = "sddm-rhine-labs";
  };

  installPhase = ''
    mkdir -p $out/share/sddm/themes/rhine-labs
    cp -r * $out/share/sddm/themes/rhine-labs/
  '';
}
