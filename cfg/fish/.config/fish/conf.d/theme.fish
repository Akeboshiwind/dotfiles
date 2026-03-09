# theme.fish — switch fish colors based on PWD

function _update_fish_theme --on-variable PWD
    if string match -q '*/prog/work*' $PWD
        set -l theme tokyonight
    else
        set -l theme kanagawa-wave
    end
    if test -f "$__fish_config_dir/themes/$theme.theme"
        source "$__fish_config_dir/themes/$theme.theme"
    end
end

_update_fish_theme
