
unalias spell 2>/dev/null
function spell
{
	echo | aspell pipe | sed -ne '1p'
	for word in $*; do
		len=${#word}
		len=$((len + 2))
		if [ $len -lt 15 ]; then
			len=15
		fi
		printf "%-${len}s" $word
		cnt=0
		echo "$word" | aspell pipe | sed -e '1d' | while read; do
			if [ -n "$(echo $REPLY)" ]; then
				if [ $cnt -eq 0 ]; then
					echo "$REPLY"
				else
					printf "%-${len}s  %s" "." "$REPLY"
					echo
				fi
				cnt=$((cnt + 1))
			fi
		done
#		echo
	done
}

