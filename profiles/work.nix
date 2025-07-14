{ user, ... }:
{ ... }: 

{
  homebrew.casks = [
    "gather"
    "slack"
    "microsoft-teams"
  ];

  homebrew.masApps = {
    "Windows App" = 1295203466;
  };
}
