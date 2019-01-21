#!/bin/bash

HERE="$(dirname "$(readlink -f "$0")")"
DOTFILES="$(dirname "${HERE}")"
source "${DOTFILES}/bash-common.sh" 2>/dev/null && eval "${capture_output}" || true

echo "Saving known ignored files."
tmp="$(mktemp -d)"
find ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune -or -name 'node_modules' -prune \) \( -name .idea -or -name '*.iml' \) -print0 | xargs -0 cp --parents -xPr --target-directory="${tmp}/" 2>/dev/null
find ./ -xdev -not \( -name '.git' -prune -or -name '.svn' -prune -or -name 'node_modules' -prune \) \( -name .project -or -name .pydevproject -or -name .cproject -or -name .settings \) -print0 | xargs -0 cp --parents -xPr --target-directory="${tmp}/" 2>/dev/null

echo
echo "Cleaning ignored files."
git clean -f -X -d

echo
echo "Restoring known ignored files."
rsync -zvPAXrogthlm "${tmp}/" ./ && rm -rf "${tmp}"
