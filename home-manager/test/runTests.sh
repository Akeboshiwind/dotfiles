#/bin/sh

SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"

cd $SCRIPT_DIR

out=$(nix eval --impure --expr 'import ./default.nix {}')

[ "$out" != "[ ]" ] && {
    echo "Test failed!"
    echo "$out"
    exit 1
}

echo "Success!"
