{
  pkgs ? import <nixpkgs> { },
}:
let
  bambu-studio = import ./default.nix { inherit pkgs; };
in
pkgs.mkShell {
  packages = [
    bambu-studio
    pkgs.strace
    pkgs.gdb
    pkgs.ltrace
  ];
}
