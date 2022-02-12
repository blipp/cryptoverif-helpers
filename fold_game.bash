#!/bin/bash

# Delete all lines that are not a branch. This shall permit to
# analyse the structure of a game more easily because more of the
# branches fit on one screen.

if [ "$#" -eq 0 ]; then
	echo "There is no game"
	exit 1
elif [ "$#" -eq 1 ] && [ "$1" = "all" ]; then
	game_fileS=$(ls g*.out.cv)
elif [ ! -f "$1" ]; then
	game_fileS="g$1.out.cv"
else
	game_fileS="$@"
fi

for game_file in $game_fileS; do
	echo $game_file
	result_file=$game_file.structure.cv
	# strip line if it does *not* begin with
	# * (, ), |
	# * !
	# * in, out
	# * if, else
	# * find, orfind
	# * event
	# * yield
	grep -E "^[ ]*(\{[0-9]+\}[ ]*)?(in|out|\(|\)|\||\!|if|else|find|orfind|event|yield)" $game_file > $result_file
done
