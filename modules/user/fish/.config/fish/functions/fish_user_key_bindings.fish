function fish_user_key_bindings
    # >> Vi mode by default
    fish_vi_key_bindings --no-erase

    # >> Override some key bindings
    # <C-f> Accept autosuggestion
    for mode in insert default visual
        bind -M $mode \cf forward-char
    end
end
