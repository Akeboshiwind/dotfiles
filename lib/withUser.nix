# withUser.nix - Import modules/profiles with user parameter


user: modulePaths:
  map (path: import path { inherit user; }) modulePaths