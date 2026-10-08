{ pkgs }:

{
  ldconfig-wrapper = pkgs.writeShellScriptBin "ldconfig" ''
    case "$*" in
      *-p*|*--print*)
        for dir in /run/current-system/sw/share/nix-ld/lib /run/opengl-driver/lib; do
          [ -d "$dir" ] && for lib in "$dir"/*.so*; do
            [ -f "$lib" ] || [ -L "$lib" ] || continue
            name=$(basename "$lib")
            echo "$name => $lib"
          done
        done
        ;;
    esac
    exit 0
  '';
}
