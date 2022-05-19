{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    coreutils posix_man_pages bash-completion less
    gitFull diffutils
    gnumake which
    ncurses perl python2 python3

    # keep this line if you use bash
    bashInteractive
  ];

  shellHook =
  ''
    alias ..='cd ..'
    alias ...='cd ../..'
  '';
}
