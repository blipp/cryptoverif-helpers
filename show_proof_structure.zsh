#!/usr/bin/zsh
#grep --color=always -E "^(Proved|Applying|Game [0-9]* is)" $1
grep --color=always -E "^(Proved|Applying equivalence|Applying)" $1
