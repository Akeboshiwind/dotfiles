{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Setup for development

  imports = withUser user [
    # >> Languages
    ../modules/user/terraform
    ../modules/user/clojure
    #../modules/user/rust
    #../modules/user/python
    #../modules/user/golang

    # >> Deployment
    ../modules/user/aws
  ];
}
