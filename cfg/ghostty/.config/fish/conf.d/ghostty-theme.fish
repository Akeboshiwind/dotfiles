# ghostty-theme.fish — switch ghostty colors based on PWD
# Uses Kitty's OSC 21 extension supported by Ghostty

test "$TERM_PROGRAM" = ghostty; or return

function _update_ghostty_theme --on-variable PWD
    if string match -q '*/prog/work*' $PWD
        # Kanagawa Dragon
        printf '\033]21;foreground=#c5c9c5;background=#181616;cursor-color=#c8c093;cursor-text=#181616;selection-foreground=#181616;selection-background=#c5c9c5;0=#0d0c0c;1=#c4746e;2=#8a9a7b;3=#c4b28a;4=#8ba4b0;5=#a292a3;6=#8ea4a2;7=#c8c093;8=#a6a69c;9=#e46876;10=#87a987;11=#e6c384;12=#7fb4ca;13=#938aa9;14=#7aa89f;15=#c5c9c5\a'
    else
        # Reset to config defaults (Kanagawa Wave)
        printf '\033]104;\a\033]110;\a\033]111;\a\033]112;\a'
    end
end

_update_ghostty_theme
