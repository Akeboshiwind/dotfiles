{ user, ... }:
{ ... }: {
  # Core tools needed everywhere

  imports = [
    # >> Terminal setup
    (import ../modules/tmux { inherit user; })
    #(import ../modules/zsh { inherit user; })
    (import ../modules/fish { inherit user; })
    (import ../modules/bash { inherit user; })

    # >> Editor
    (import ../modules/nvim { inherit user; })
    (import ../modules/vim { inherit user; })

    # >> Tools
    (import ../modules/git { inherit user; })
    (import ../modules/ssh { inherit user; })
    (import ../modules/gpg { inherit user; })
    (import ../modules/fzf { inherit user; })
    (import ../modules/zoxide { inherit user; })
    (import ../modules/bin { inherit user; })
  ];
}
