#!/bin/bash

funk=
case `echo $1 | tr [:upper:] [:lower:]` in
	c | change)
		funk="change"
		shift
	;;
	r | release)
		funk="release"
		shift
	;;
esac
if [ -z "$funk" ]; then
	read -n1 -p "Are you making a [C]hange or a [R]elease? " FUN
	echo
	case `echo $FUN | tr [:upper:] [:lower:]` in
		c | change)
			funk="change"
		;;
		r | release)
			funk="release"
		;;
	esac
fi
if [ "$funk" = "change" ]; then
	debchange --check-dirname-level=0 -M --force-distribution -l. "$@"
else
	if [ "$funk" = "release" ]; then
		dist=
		case `echo $1 | tr [:upper:] [:lower:]` in
			d | dev*)
				dist="development"
				shift
			;;
			p | prod*)
				dist="production"
				shift
			;;
		esac
		if [ -z "$dist" ]; then
			read -n1 -p "Are you releasing for [D]evelopment, [P]roduction or Other? " DIS
			case `echo $DIS | tr [:upper:] [:lower:]` in
				d | dev*)
					dist="development"
				;;
				p | prod*)
					dist="production"
				;;
				*)
					read -i "$DIS" DIS
					dist=`echo $DIS | tr [:upper:] [:lower:]`
				;;
			esac
			echo
		fi
		if [ -z "$dist" ]; then
			debchange --check-dirname-level=0 -M --force-distribution -r "$@"
		else
			debchange --check-dirname-level=0 -M --force-distribution -D "$dist" -r "$@"
		fi
	else
		echo "Invalid function chosen!  How did you even do that?"
		false
	fi
fi
