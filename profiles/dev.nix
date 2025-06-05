{ user, ... }:
{ ... }: 

let
  withUser = import ../lib/withUser.nix;
in
{
  # Setup for development

  imports = withUser user [
    # >> Languages
    ../modules/terraform
    ../modules/clojure
    #../modules/rust
    #../modules/python
    #../modules/golang

    # >> Deployment
    ../modules/aws
  ];
}
