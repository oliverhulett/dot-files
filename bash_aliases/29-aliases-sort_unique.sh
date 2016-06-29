## Call sort on files, write results back to files
function sortinline()
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
		echo "sort ${ARGS[@]} $f"
		echo "$(sort "${ARGS[@]}" "$f")" >"$f"
	done
}

## Call uniq on files, write results back to files
function uniqinline()
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
		echo "uniq ${ARGS[@]} $f"
		echo "$(uniq "${ARGS[@]}" "$f")" >"$f"
	done
}

