#!/bin/zsh

# In addition to get_occ.zsh this script can be used to analyse after
# the fact if the occurrence numbers written in a model's `insert`
# command are those wanted by the user. It does so by reading the
# model file, executing each command defined by the user to get the
# occurrence numbers and comparing if the command returns the same
# number.
# This can be used to verify the occurrence numbers even if CryptoVerif
# was already started and already produced the intermediate `out_game`
# files.

if [[ $# -ne 1 ]]; then
	echo "Usage: $0 <model.cv>"
	exit 1
fi
model=$1

occ_actual=()

# TODO: this should only consider the latest commandline before a
#       not-commented insert. Thus we need a bit of the same logic
#       than in get_occ.zsh.

# read line by line
grep "commandline = " $model | while read -r line; do
	if [[ "$line" =~ "\(\* commandline = (.+) \*\)" ]]; then
		commandline=${match[1]}
		occ=$(eval ${commandline})
		occ_actual+=$occ
	fi
done

i=1
differences=0
grep -E "insert [0-9]+ " $model | awk '{print $2}' | while read -r line; do
	if [[ "$line" = "$occ_actual[$i]" ]]; then
		echo $line
	else
		echo "$line should be $occ_actual[$i]"
		((differences++))
	fi
	((i++))
done

if [[ $differences -eq 0 ]]; then
	echo "All the same."
	exit
else
	echo "There are differences you should fix."
	exit 2
fi
