# Navigate to the current Python virtual env's site packages directory

function site-packages()
{
	sp="/usr/lib64/python2.7/site-packages/"
	for p in python python2.7 python26; do
		thon="$(command which $p 2>/dev/null)"
		if [ -n "$thon" ]; then
			if [[ $thon != /bin/python* ]]; then
				for d in "$(basename "$thon")" python2.7 python2.6 python26 python python3 python3.4; do
					for l in lib64 lib; do
						dir="$(dirname "$thon")/../$l/$d/site-packages"
						if [ -d "$dir" ]; then
							sp="$(cd "$dir" && pwd -P)"
							break 3
						fi
					done
				done
			fi
		fi
	done
	echo "$sp"
}
