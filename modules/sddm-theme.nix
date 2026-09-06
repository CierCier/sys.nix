{ stdenv }:

stdenv.mkDerivation {
  pname = "sddm-rhine-labs";
  version = "1.0";

  src = ./sddm-rhine-labs;

  installPhase = ''
    mkdir -p $out/share/sddm/themes/rhine-labs
    cp -r * $out/share/sddm/themes/rhine-labs/
  '';
}
