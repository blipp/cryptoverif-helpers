#!/bin/bash

# Add some whitespace between parallel processes to make it more
# readable for CryptoVerif beginners. More advanced users get
# used to it quickly ;)

if [ "$#" -eq 0 ]; then
	echo "There is no game"
	exit 1
elif [ "$#" -eq 1 ] && [ "$1" = "all" ]; then
	GAME_FILES=$(ls g*.out.cv)
elif [ ! -f "$1" ]; then
	GAME_FILES="g$1.out.cv"
else
	GAME_FILES="$@"
fi

#GAME_FILE=$1
#if [ ! -f $GAME_FILE ]; then
	#GAME_FILE=g$1.out.cv
#elif [ ! -f $GAME_FILE ]; then
	#echo "Neither $1 nor $GAME_FILE have been found. Exiting."
	#exit 1
#fi
for GAME_FILE in $GAME_FILES; do
	echo $GAME_FILE
	sed -i -r -e 's/^([ ]*\{[1-9]*\}[ ]*\(\()/\n\n\1\n\n/' $GAME_FILE
	#sed -i -e 's/^[ ]*(($/\n\n((\n\n/' -e 's/^[ ]*) | ($/\n\n) | (\n\n/' -e 's/^[ ]*))$/\n\n))\n\n/' $GAME_FILE
	sed -i -r -e 's/^([ ]*\(\()$/\n\n\1\n\n/' -e 's/^([ ]*\) \| \()$/\n\n\1\n\n/' -e 's/^([ ]*\)\))$/\n\n\1\n\n/' $GAME_FILE
done
