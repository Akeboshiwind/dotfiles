# Fish config

# >> Load wal colours
cat ~/.cache/wal/sequences &

# >> Abbreviations
if not set -q abbrs_initialized
    set -U abbrs_initialized
    echo -n Setting abbreviations...

    # >> ls
    abbr --add l ls
    abbr --add sl ls

    # >> tree
    abbr --add tree 'tree -C'

    echo Done
end
