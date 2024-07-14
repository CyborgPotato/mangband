{ stdenv
, lib
, fetchFromGitHub
, autoreconfHook
, binutils
# TODO enableCRB: Carbon/macOS client
, enableX11  ? false
, enableSDL  ? true
, enableSDL2 ? false
, enableGCU  ? true
, SDL
, SDL_image
, SDL_ttf
, SDL2
, SDL2_image
, SDL2_ttf
, ncurses
, libX11
}: stdenv.mkDerivation {
  pname = "mangband";
  version = "03-13-2022";

  src = fetchFromGitHub {
    owner = "mangband";
    repo = "mangband";
    rev = "c97e8738f81a3d1b6d8d1b8222064a99c7bc2473";
    hash = "sha256-VeJTrz3cYryb1H9MWauK7odIgG9x5z7QOEC9Asv3GnY=";
  };

  prePatch = ''
    substituteInPlace src/common/net-imps.c --replace "sys/unistd.h" "unistd.h"
  '';

  configureFlags = let
    f' = x: if x then "yes" else "no";
  in [
    "--with-x11=${f' enableX11}"
    "--with-gcu=${f' enableGCU}"
    "--with-sdl=${f' enableSDL}"
    "--with-sdl-image=${f' enableSDL}"
    "--with-sdl-ttf=${f' enableSDL}"
    "--with-sdl2=${f' enableSDL2}"
    "--with-sdl2-image=${f' enableSDL2}"
    "--with-sdl2-ttf=${f' enableSDL2}"
  ];

  nativeBuildInputs = [
    autoreconfHook
  ];

  buildInputs = with lib;
    optionals enableX11 [
      libX11
    ] ++ optionals enableSDL [
      SDL
      SDL_image
      SDL_ttf
    ] ++ optionals enableSDL2 [
      SDL2
      SDL2_image
      SDL2_ttf
    ] ++ optionals enableGCU [
      ncurses
    ] ++ optionals stdenv.hostPlatform.isStatic [
      binutils
    ];
}
