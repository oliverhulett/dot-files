## Call sort on files, write results back to files
function sortinline()
{
	KEEP_BLANK="no"
	ARGS=()
	FILES=()
	for f in "$@"; do
		if [ -f "$f" ]; then
			FILES[${#FILES[@]}]="$(readlink -e "$f")"
		else
			if [ "$f" == "--keep" ]; then
				KEEP_BLANK="yes"
			else
				ARGS[${#ARGS[@]}]="$f"
			fi
		fi
	done
	for f in "${FILES[@]}"; do
		echo "sort ${ARGS[@]} $f"
		echo "$(sort "${ARGS[@]}" "$f")" >"$f"
	done
	if [ "$KEEP_BLANK" == "no" ]; then
		cleaninline "${FILES[@]}"
	fi
}

## Call uniq on files, write results back to files
function uniqinline()
{
	KEEP_BLANK="no"
	ARGS=()
	FILES=()
	for f in "$@"; do
		if [ -f "$f" ]; then
			FILES[${#FILES[@]}]="$(readlink -e "$f")"
		else
			if [ "$f" == "--keep" ]; then
				KEEP_BLANK="yes"
			else
				ARGS[${#ARGS[@]}]="$f"
			fi
		fi
	done
	for f in "${FILES[@]}"; do
		echo "uniq ${ARGS[@]} $f"
		echo "$(uniq "${ARGS[@]}" "$f")" >"$f"
	done
	if [ "$KEEP_BLANK" == "no" ]; then
		cleaninline "${FILES[@]}"
	fi
}

## Clean files of empty lines, write result back to files
function cleaninline()
{
	ARGS=()
	FILES=()
	for f in "$@"; do
		if [ -f "$f" ]; then
			FILES[${#FILES[@]}]="$(readlink -e "$f")"
		else
			ARGS[${#ARGS[@]}]="$f"
		fi
	done
	for f in "${FILES[@]}"; do
		echo "sed -re '/^$/d' ${ARGS[@]} -i $f"
		sed -re '/^$/d' "${ARGS[@]}" -i "$f"
	done
}

## Add items to a list file.  Keep the list file sorted, uniq-ified, and clean of empty lines.
function list()
{
	ARGS=()
	FILE=""
	LIST=()
	for a in "$@"; do
		if [ "${a:0:1}" == "-" ]; then
			ARGS[${#ARGS[@]}]="$a"
		else
			if [ -z "${FILE}" ]; then
				FILE="$a"
			else
				LIST[${#LIST[@]}]="$a"
			fi
		fi
	done
	for l in "${LIST[@]}"; do
		echo "Adding: $l"
		echo "$l" >>"${FILE}"
	done
	sortinline -u "${FILE}"
}
