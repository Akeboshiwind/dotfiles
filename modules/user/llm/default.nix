{ user, ... }:
{ config, pkgs, ... }:

{
  homebrew.casks = [
    "claude"
    #"ollama"
  ];

  users.users."${user}" = {
    packages = with pkgs; [
      claude-code
      llm
      repomix
    ];
  };

  home-manager.users."${user}" = {
    custom.home.folders = [
      { source = ./.; exclude = ["default.nix"]; }
    ];
  };
}
