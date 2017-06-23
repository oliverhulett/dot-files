## Validate JSON
function jsoncheck()
{
	source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
	for f in "$@"; do
		echo -n "Validating '$f': "
		python -m json.tool "$f" >&${log_fd}
		if [ 0 -eq $? ]; then
			echo "Good"
		else
			echo "Failed"
		fi
	done
}

## Pretty print JSON
function jsonpretty()
{
	source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
	for f in "$@"; do
		python -m json.tool "$f" >&${log_fd} && echo "$(python -m json.tool "$f")" >"$f"
	done
}

## Validate YAML
function yamlcheck()
{
	source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
	for f in "$@"; do
		echo -n "Validating '$f': "
		python >&${log_fd} <<-EOF
			import sys
			import yaml

			try: print yaml.load(open("$f", 'r').read())
			except: sys.exit(1)

			sys.exit(0)
		EOF
		if [ 0 -eq $? ]; then
			echo "Good"
		else
			echo "Failed"
		fi
	done
}

## Pretty print YAML
function yamlpretty()
{
	source "$(dirname "$(readlink -f "${BASH_SOURCE}")")/../bash_common.sh" 2>/dev/null && eval "${setup_log_fd}" || true
	for f in "$@"; do
		python >&${log_fd} <<-EOF
			from ruamel.yaml import YAML
			yaml = YAML(typ='rt')
			yaml.top_level_colon_align = True
			yaml.preserve_quotes = True
			doc = yaml.load(open("$f", 'r').read())
			yaml.dump(doc, open("$f", 'w'))
		EOF
	done
}
