# >> asdf


# >> Config

prefix=$(brew-prefix asdf)
asdf_completion_path=$COMPLETION_PATH/_asdf



# >> Setup

. $prefix/asdf.sh



# >> Completions

[ -e "$asdf_completion_path" ] || {
    cp $prefix/share/zsh/site-functions/_asdf $asdf_completion_path
}
