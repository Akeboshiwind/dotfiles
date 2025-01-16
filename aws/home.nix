{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    awscli2
    aws-vault
  ];

  home.file = {
    ".aws" = {
      source = ./.aws;
      recursive = true;
    };
    ".zsh/aws.zsh".source = ./.zsh/aws.zsh;
  };
}
