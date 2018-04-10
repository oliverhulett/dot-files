# shellcheck shell=bash

function gdl()
{
	"$(get-project-root)/gradlew" "$@"
}
complete -F _gradle gdl
