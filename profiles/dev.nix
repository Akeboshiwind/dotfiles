{ user, ... }:
{ ... }: {
  # Setup for development

  imports = [
    # >> Languages
    (import ../modules/terraform { inherit user; })
    (import ../modules/clojure { inherit user; })
    #(import ../modules/rust { inherit user; })
    #(import ../modules/python { inherit user; })
    #(import ../modules/golang { inherit user; })

    # >> Deployment
    (import ../modules/aws { inherit user; })
  ];
}
