#!/bin/bash -e

## If we're using dependencies.json, check that it is sane.
if [ -f ./dependencies.json ]; then
	python -m json.tool ./dependencies.json
fi
## If we're using externals.json, check that it is sane.
if [ -f ./externals.json ]; then
	python -m json.tool ./externals.json
elif [ -f ./deps.json ]; then
	python -m json.tool ./deps.json
fi

## `git updat e-c` is a common typo when fingers outpace brains.  Git will correctly guess that you meant `git update` but not that you meant `git update -c`.
if [ "$1" == "-c" -o "$1" == "--clean" -o "$1" == "e-c" -o "$1" == "ec-" -o "$1" == "-ec" -o "$1" == "-ce" ]; then
	if [ -f ./pins.json ]; then
		echo "Removing externals from: pins.json"
		sed -nre 's/^[ \t]+"(.+)": \{/\1/p' ./pins.json | tee >(xargs rm -rf) | xargs
	fi
	find ./ -not \( -name .git -prune -or -name .svn -prune \) -name externals.json | while read; do
		echo "Removing externals from: $REPLY"
		sed -nre 's/^[ \t]+"(.+)": \{/\1/p' "$REPLY" | tee >(cd "$(dirname "$REPLY")" && xargs rm -rf) | xargs
	done
	echo "Removing '.gitexternals', '.git/externals/', and likely external directories: " x_*
	rm -rf .gitexternals .git/externals x_* 2>/dev/null || true

	git submodule deinit --force .
else
	if [ -f ".gitsvnextmodules" -o -f "gitsvnextmodules" -o -f "externals.json" -o -f "deps.json" ]; then
		OUT1="$(python ./git_setup.py -kq 2>&1)" || OUT2="$(getdep 2>&1)" || OUT3="$(courier 2>&1)" || ( echo -e "python ./git_setup.py -kq\n${OUT1}\n\ngetdep\n${OUT2}\n\ncourier\n${OUT3}\n" && false )
		if [ -n "${OUT3}" ]; then
			echo -ne "${OUT3}\n"
			## Special case if we ran courier, remove commit hooks installed by `getdep`.
			getdep_hook="$(dirname $(dirname $(/usr/bin/which getdep)))/lib/python2.7/site-packages/getdep/hooks/pull-if"
			for hook in post-checkout post-commit post-merge; do
				if [ -L ".git/hooks/${hook}" -a ".git/hooks/${hook}" -ef "${getdep_hook}" ]; then
					rm ".git/hooks/${hook}"
				fi
			done
		elif [ -n "${OUT2}" ]; then
			echo -ne "${OUT2}\n"
		elif [ -n "${OUT1}" ]; then
			echo -ne "${OUT1}\n"
		fi
	fi
	
	git submodule init
	git submodule sync
	git submodule update
fi
