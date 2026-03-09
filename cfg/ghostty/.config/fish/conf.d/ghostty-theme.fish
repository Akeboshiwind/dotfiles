# ghostty-theme.fish — switch ghostty colors based on PWD
# Uses Kitty's OSC 21 extension supported by Ghostty

test "$TERM_PROGRAM" = ghostty; or return

function _update_ghostty_theme --on-variable PWD
    if string match -q '*/prog/work*' $PWD
        # Tokyo Night
        printf '\033]21;foreground=#c0caf5;background=#1a1b26;cursor-color=#c0caf5;cursor-text=#1a1b26;selection-foreground=#c0caf5;selection-background=#283457;0=#15161e;1=#f7768e;2=#9ece6a;3=#e0af68;4=#7aa2f7;5=#bb9af7;6=#7dcfff;7=#a9b1d6;8=#414868;9=#f7768e;10=#9ece6a;11=#e0af68;12=#7aa2f7;13=#bb9af7;14=#7dcfff;15=#c0caf5\a'
    else
        # Reset to config defaults (Kanagawa Wave)
        printf '\033]104;\a\033]110;\a\033]111;\a\033]112;\a'
    end
end

_update_ghostty_theme
