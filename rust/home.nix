{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    rustup
    
    # llvm
    # python3
    cmake
    openssl
  ];

  home.file = {
    ".zsh/rust.zsh".source = ./.zsh/rust.zsh;
  };
}
