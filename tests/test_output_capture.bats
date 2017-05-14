## Tests _hidex and _restorex
@test "_hidex unsets -x and remembers incoming value" {
	skip
	source "${DOTFILES}/bash_common.sh"
	set -x
	run eval "${_hidex}"
}
