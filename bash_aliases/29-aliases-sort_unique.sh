## Call sort on files, write results back to files
function sortinline()
{
	KEEP_BLANK="no"
	ARGS=()
	FILES=()
	for f in "$@"; do
		if [ -f "$f" ]; then
			FILES[${#FILES[@]}]="$f"
		else
			if [ "$f" == "--keep" ]; then
				KEEP_BLANK="yes"
			fi
			ARGS[${#ARGS[@]}]="$f"
		fi
	done
	for f in "${FILES[@]}"; do
		echo "sort ${ARGS[@]} $f"
		echo "$(sort "${ARGS[@]}" "$f")" >"$f"
		if [ "$KEEP_BLANK" == "no" ]; then
			cleaninline $f
		fi
	done
}

## Call uniq on files, write results back to files
function uniqinline()
{
	KEEP_BLANK="no"
	ARGS=()
	FILES=()
	for f in "$@"; do
		if [ -f "$f" ]; then
			FILES[${#FILES[@]}]="$f"
		else
			if [ "$f" == "--keep" ]; then
				KEEP_BLANK="yes"
			fi
			ARGS[${#ARGS[@]}]="$f"
		fi
	done
	for f in "${FILES[@]}"; do
		echo "uniq ${ARGS[@]} $f"
		echo "$(uniq "${ARGS[@]}" "$f")" >"$f"
		if [ "$KEEP_BLANK" == "no" ]; then
			cleaninline $f
		fi
	done
}

## Clean files of empty lines, write result back to files
function cleaninline()
{
	ARGS=()
	FILES=()
	for f in "$@"; do
		if [ -f "$f" ]; then
			FILES[${#FILES[@]}]="$f"
		else
			ARGS[${#ARGS[@]}]="$f"
		fi
	done
	for f in "${FILES[@]}"; do
		echo "sed -re '/^$/d' ${ARGS[@]} -i $f"
		sed -re '/^$/d' "${ARGS[@]}" -i "$f"
	done
}

