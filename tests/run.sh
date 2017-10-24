#!/bin/bash

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DOTFILES="$(dirname "${HERE}")"
PATH="${DOTFILES}/bin:$PATH"
export HERE DOTFILES PATH

function help()
{
	bats --help
	echo "Pretty mode doesn't work here, until I can capture and aggregate the summaries."
	echo
	echo "Additional options:"
	FMT="  %- 18s %s\n"
	# shellcheck disable=SC2059
	printf "${FMT}"  "-l, --list" "List the test files that would be run with the given arguments."
	# shellcheck disable=SC2059
	printf "${FMT}"  "-r, --parallel=N" "(-p was taken) Run tests in parallel, using N processes.  Defaults to 2 * \`nproc' (2 * $(nproc) = $((2 * $(nproc))))"
	echo
}

OPTS=$(getopt -o "chtpvlr:" --long "count,help,tap,pretty,version,list,parallel:" -n "$(basename -- "$0")" -- "$@")
es=$?
if [ $es != 0 ]; then
	help
	exit $es
fi

PARALLEL=$(( $(nproc) * 2 ))
ARGS=( "-t" )
COUNT="false"
LIST="false"
TAP="true"
eval set -- "${OPTS}"
while true; do
	case "$1" in
		-h | '-?' | --help )
			help
			exit
			;;
		-v | --version )
			bats --version
			exit
			;;
		-c | --count )
			COUNT="true"
			shift
			;;
		-l | --list )
			LIST="true"
			shift
			;;
		-t | --tap )
			ARGS=( ${ARGS[@]/$1} )
			ARGS[${#ARGS[@]}]="$1"
			shift
			;;
		-p | --pretty )
			# shellcheck disable=SC2034
			TAP="false"
			ARGS=( ${ARGS[@]/$1} )
			ARGS[${#ARGS[@]}]="$1"
			shift
			;;
		-r | --parallel )
			if [ -n "$2" ] && command grep -qwE '^[0-9]+$' <(echo "$2") 2>/dev/null && [ "$2" -ne 0 ]; then
				PARALLEL=$2
			fi
			shift 2
			;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

function get_all_test_files()
{
	if [ $# -eq 0 ]; then
		set -- "$(dirname "${BASH_SOURCE[0]}")"
	fi
	find "$@" -not \( -name '.git' -prune -or -name '.svn' -prune -or -name '.venv' -prune -or -name '.virtualenv' -prune -or -name 'x_*' -prune \) \( -name '*.bats' \) | sort -u
}

function count()
{
	cnt=0
	for f in "$@"; do
		cnt=$((cnt + $(bats --count "$f")))
	done
	echo "$cnt"
}

# shellcheck disable=SC2046
set -- $(get_all_test_files "$@")

if [ "${COUNT}" == "true" ]; then
	count "$@"
	exit
fi

NUM_TESTS=$(count "$@")
if [ "$#" -lt "${PARALLEL}" ]; then
	PARALLEL=$#
fi

TESTS="tests"
if [ "${NUM_TESTS}" -eq 1 ]; then
	TESTS="test"
fi
FILES="files"
if [ "$#" -eq 1 ]; then
	FILES="file"
fi
PROCESSES="processes"
if [ "${PARALLEL}" -eq 1 ]; then
	PROCESSES="process"
fi
if [ "${LIST}" == "true" ]; then
	echo "Running ${NUM_TESTS} ${TESTS} in $# ${FILES} using at most ${PARALLEL} ${PROCESSES}"
	printf "%s\n" "$@"
	exit
else
	echo "Running ${NUM_TESTS} ${TESTS} in $# ${FILES} using at most ${PARALLEL} ${PROCESSES}"
fi

TD="/tmp/bats/$(date '+%Y%m%d-%H%M%S')"
rm -rf "${TD}"
mkdir --parents "${TD}"

WIDTH=0
for a in "$@"; do
	f="$(basename -- "$a" .bats)"
	if [ ${#f} -gt ${WIDTH} ]; then
		WIDTH=${#f}
	fi
done

TIME=( $(command which time) -f "\n%E (%P)  User: %U secs  Sys: %S secs\nMax Mem: %M kb\nCtx Sw: %w (Inv: %c)\nFS in: %I  FS out: %O" )

printf " % ${WIDTH}s %s\n" ":" "1..${NUM_TESTS}"
printf "%s\0" "$@" | stdbuf -oL "${TIME[@]}" xargs -r0 -n 1 -P "${PARALLEL}" -I{} sh -c "
	export FN=\"\$(basename -- \"{}\" .bats)\";
	export TD=\"${TD}/\${FN}\";
	mkdir \"\$TD\";
	export TMPDIR=\"\$TD\";
	export BATS_TMPDIR=\"\$TD\";
	export BATS_MOCK_TMPDIR=\"\$TD\";
	bats ${ARGS[*]} {} | sed -nre \"2,\\\$s/^/\$(printf \"%- ${WIDTH}s\" \"\${FN}\"): /p\";
" | stdbuf -oL perl -e '
	$| = 1;
	my $cnt = 0;
	my $success = 0;
	my $skip = 0;
	my $failure = 0;
	while (<STDIN>) {
		if (m/^(.{'${WIDTH}'}: )((not )?ok )([0-9]+)(( # skip \()?.+)$/) {
			$cnt++;
			my $colour = "";
			my $file = $1;
			my $result = $2;
			my $name = $5;
			if ($result =~ /^not ok $/) {
				$failure++;
				$colour = "\e[31m";
			} elsif ($name =~ /^ # skip \(/) {
				$skip++;
				$colour = "\e[34m";
			} else {
				$success++;
				$colour = "\e[32m";
			}
			print $file . $colour . $result . $cnt . $name . "\e[0m\n";
		} else {
			print $_;
		}
	}
	print "\n";
	my $tests = " tests";
	if ($cnt == 1) {
		$tests = " test";
	}
	print "Ran " . $cnt . $tests . ": " . $success . " succeeded; " . $skip . " skipped; " . $failure . " failed.\n";
'
