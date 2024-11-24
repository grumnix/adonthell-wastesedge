{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";

    adonthell_src.url = "git://git.sv.nongnu.org/adonthell.git";
    adonthell_src.flake = false;

    adonthell-wastesedge_src.url = "git://git.sv.nongnu.org/adonthell/adonthell-wastesedge.git";
    adonthell-wastesedge_src.flake = false;
  };

  outputs = { self, nixpkgs, flake-utils, adonthell_src, adonthell-wastesedge_src }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        python = pkgs.python3.withPackages(ps: with ps; [ distutils ]);
      in {
        packages = rec {
          default = adonthell-wastesedge;

          adonthell = pkgs.stdenv.mkDerivation rec {
            pname = "adonthell";
            version = "0.3.8";

            src = adonthell_src;

            enableParallelBuilding = true;

            postPatch = ''
              substituteInPlace configure.ac \
                --replace 'distutils.sysconfig.get_config_var("LIBPL")' \
                          '"${python}/lib"'
            '';

            CPPFLAGS = ''-I${pkgs.SDL2.dev}/include/SDL2 -I${pkgs.SDL2_mixer.dev}/include/SDL2 -I${pkgs.SDL2_ttf}/include/SDL2'';

            nativeBuildInputs = with pkgs; [
              autoreconfHook
              bison
              flex
              pkg-config
              swig3
            ] ++ [
              python
            ];

            buildInputs = with pkgs; [
              SDL2
              SDL2_mixer
              SDL2_ttf
              freetype
              gtk2
              zlib
            ];
          };

          adonthell-wastesedge = pkgs.stdenv.mkDerivation rec {
            pname = "adonthell-wastesedge";
            version = "0.3.8";

            src = adonthell-wastesedge_src;

            configurePhase = ''
              ./configure \
                --disable-dependency-tracking \
                --prefix=$out \
                --with-data-dir=$out/share/adonthell
            '';

            postFixup = ''
              substituteInPlace $out/bin/adonthell-wastesedge \
                --replace adonthell-0.3 ${adonthell}/bin/adonthell-0.3 \
                --replace wastesedge "-g $out/share/adonthell/games/wastesedge"
            '';

            nativeBuildInputs = with pkgs; [
              autoreconfHook
              pkg-config
            ];

            buildInputs = [
              adonthell
            ];
          };
        };
      }
    );
}

