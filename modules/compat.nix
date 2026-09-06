{ pkgs }:

{
  libcrypt-compat = pkgs.stdenv.mkDerivation {
    name = "libcrypt-compat";
    src = pkgs.writeText "shim.c" ''
      #define _GNU_SOURCE
      #include <stddef.h>
      #include <dlfcn.h>
      #include <crypt.h>

      asm(".symver crypt_r_compat, crypt_r@@GLIBC_2.2.5");

      char *crypt_r_compat(const char *key, const char *salt, struct crypt_data *data) {
        static char *(*real_crypt_r)(const char *, const char *, struct crypt_data *) = NULL;
        if (!real_crypt_r) {
          real_crypt_r = (char *(*)(const char *, const char *, struct crypt_data *))dlsym(RTLD_NEXT, "crypt_r");
        }
        return real_crypt_r(key, salt, data);
      }
    '';
    phases = [
      "buildPhase"
      "installPhase"
    ];
    buildPhase = ''
      gcc -shared -fPIC \
        -Wl,--version-script=${pkgs.writeText "shim.ld" "GLIBC_2.2.5 { crypt_r; };"} \
        -o libcrypt.so.1 "$src" -ldl -lcrypt
    '';
    installPhase = ''
      mkdir -p $out/lib
      cp libcrypt.so.1 $out/lib/
    '';
    buildInputs = [ pkgs.libxcrypt ];
  };

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
