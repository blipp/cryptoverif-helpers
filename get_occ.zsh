#!/bin/zsh

# Process a cv file with special comments and automatically find the
# right occurrence numbers. Before each `insert` line within the
# proof environment, add a line with the following syntax:
# (* commandline = … *)
# Where the dots shall be replaced by a shell command that returns the
# occurrence number. This shell command will probably rely on processing
# a game file, so this script will replace any occurrence of
# g[0-9]+.out.cv by the name of a temporary game file produced by
# a automatically added `out_game … occ` command.
# A pipe to sed -e 's/[^{]*{//' -e 's/}.*//' can be used for example
# to extract the occurrence number from "   {123}  foo".

if [[ $# -ne 3 ]]; then
	echo "Usage: $0 <path-to-cryptoverif> <library.cvl> <model.cv>"
	exit 1
fi

cryptoverif=$1
lib=$2
model=$3
model_header=$model.header.cv
model_body=$model.body.cv
model_tmp=$model.tmp.cv
model_final=$model.final.cv
cryptoverif_output=$model.tmp.cvres

echo $cryptoverif

# ensure those files are empty
truncate -s 0 $model_tmp
truncate -s 0 $model_final

# Generate header and body by removing the proof environment.
sed -n '/proof {/,/^}/p' $model > $model_header
sed '/proof {/,/^}/d' $model > $model_body

# read line by line
while IFS='' read -r line || [[ -n "$line" ]]; do
	# if starts with insert
	if [[ "$line" =~ "^([ ]*)insert [0-9]+ (.+);" ]]; then
		insert_whitespace=${match[1]}
		insert_term=${match[2]}
		# generate new unique file name and add out_game line
		game_file=$(mktemp gXXXXX.out.cv)
		# no ; at the end because this is the last command
		# in the proof environment
		echo "${insert_whitespace}out_game \"$game_file\" occ" >> $model_tmp
		echo "}" >> $model_tmp
		cat $model_body >> $model_tmp
		# run CryptoVerif on it
		echo "Wait for CryptoVerif to finish…"
		$cryptoverif -lib $lib $model_tmp > $cryptoverif_output
		if [[ 0 -ne $? ]]; then
			echo "CryptoVerif failed, strange! Here is its output:"
			echo "$cryptoverif_output"
			tail -n 5 $cryptoverif_output
			echo "And here the output generated starting with the initial file:"
			$cryptoverif -lib $lib $model
			exit 1; fi
		# test if the game file was generated, if no abort
		if [[ ! -f $game_file ]]; then echo "Game file $game_file not created"; exit 2; fi
		# run the commandline on the game file
		if [[ "$commandline" =~ "(.*) g[0-9]+.out.cv (.*)" ]]; then
			prepared_commandline="${match[1]} $game_file ${match[2]}"
		else
			echo "Commandline does not match expected pattern:"
			echo $commandline
			exit 3
		fi
		echo "\t$prepared_commandline"
		occ=$(eval ${prepared_commandline})
		# insert the occ number into the insert line and add it to the cv file
		#insert_line="${$line/insert[ ]+ [0-9]+ /insert $occ }"
		insert_line="${insert_whitespace}insert $occ ${insert_term};"
		echo "$insert_line" >> $model_final
		echo "\t$insert_line"
		# clear
		commandline=""
		prepared_commandline=""
		rm $game_file
		# Prepare tmp file for next iteration, basically
		# removing the body and the closing } of proof.
		cp $model_final $model_tmp

	# does not start with insert
	else
		# If line starts with command for our script,
		# extract it to a variable.
		if [[ "$line" =~ "\(\* commandline = (.+) \*\)" ]]; then
			commandline=${match[1]}

		# If we reached the end of the proof environment,
		# escape from the loop so we can finish up.
		elif [[ "$line" =~ "^}" ]]; then
			break
		fi

		# Write line to cv file.
		echo "$line" >> $model_tmp
		echo "$line" >> $model_final
	fi
done < "$model_header"

# Finish the model file.
echo "}" >> $model_final
cat $model_body >> $model_final

# Ask the user if they want to copy it to the original file.
echo "\nHere are the differences:\n"
diff $model $model_final
echo "\n"
read -q answer\?"Want to take them [yN]?"
if [[ "$answer" = "y" ]]; then
	cp $model_final $model
	echo "\nCopied to $model"
else
	echo "\nDid not copy."
fi

# Cleanup.
rm $model_header $model_body $model_tmp $cryptoverif_output
echo "Done."
exit 0
