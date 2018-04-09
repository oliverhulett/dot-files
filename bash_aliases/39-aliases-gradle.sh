# shellcheck shell=bash

function gdl()
{
	alias cat='command cat'
	"$(get-project-root)/gradlew" "$@"
}
complete -F _gradle gdl
