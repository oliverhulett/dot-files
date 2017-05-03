#!/bin/bash

MAILER="C:/Users/olihul/things/mailsend1.19.exe/mailsend1.19.exe"
ZIPPER="C:/Program Files/7-Zip/7z.exe"
HERE="$(dirname "$0")"
HASH_FILE="${HERE}/.last-mailed-hash"

cd "${HERE}" || ( echo "Failed to enter run directory.  Press any key to exit"; read -r -n1; exit 1 )
git pullb

TODAY="$(date '+%Y-%m-%d')"
LAST_HASH="$(sed -ne '1p' "${HASH_FILE}")"
NEXT_HASH="$(git rev-parse HEAD)"
echo
echo "Syncing from ${LAST_HASH} to ${NEXT_HASH}"

PATCHES_ROOT="${TODAY}.dotfiles"
ZIPFILE="${PATCHES_ROOT}.7z"
rm -rf "${PATCHES_ROOT}" "${ZIPFILE}" 2>/dev/null
mkdir "${PATCHES_ROOT}"

NUM_PATCHES=0
echo
echo "Using list files: " files.*
for f in files.*; do
	d="$(echo $f | sed -re 's/^files.//')"
	mkdir "${PATCHES_ROOT}/$d" 2>/dev/null
	echo
	echo "Formatting patches from ${LAST_HASH} for $f"
	fmt_cmd="git format-patch --output-directory=${PATCHES_ROOT}/$d --no-binary --attach --to oliver.hulett@gmail.com ${LAST_HASH} -- $(xargs <$f)"
	echo $fmt_cmd
	np=$($fmt_cmd | command grep -cv '^\s*$')
	NUM_PATCHES=$(( NUM_PATCHES + np ))
done
if [ $NUM_PATCHES == 0 ]; then
	echo
	echo "No patches formatted, not sending e-mail.  Press any key to exit"
	read -r -n1
	exit 0
fi

echo
echo "Zipping $NUM_PATCHES patches"
ls -lR "${PATCHES_ROOT}"
echo "${ZIPPER}" a "${ZIPFILE}" "${PATCHES_ROOT}"
"${ZIPPER}" a "${ZIPFILE}" "${PATCHES_ROOT}"
if [ ! -s "${ZIPFILE}" ]; then
	echo "Failed to zip patches, not sending e-mail.  Press any key to exit"
	read -r -n1
	exit 0
fi

echo
echo "Mailing $NUM_PATCHES patches"
echo "${MAILER}" -smtp unixmail.comp.optiver.com -f olihul@optiver.com.au -t oliver.hulett@gmail.com -sub "${TODAY} dotfiles" -attach "${ZIPFILE}",application/x-7z-compressed,a
"${MAILER}" -smtp unixmail.comp.optiver.com -f olihul@optiver.com.au -t oliver.hulett@gmail.com -sub "${TODAY} dotfiles" -attach "${ZIPFILE}",application/x-7z-compressed,a
echo
echo "Removing $PATCHES_ROOT and $ZIPFILE"
rm -rf "${PATCHES_ROOT}" "${ZIPFILE}"
rm -rf "${PATCHES_ROOT}"

echo
echo "Committing last mailed hash: ${NEXT_HASH}"
echo ${NEXT_HASH} >"${HASH_FILE}"
unix2dos "${HASH_FILE}"
git commit .last-mailed-hash -m"Sync2Home autocommit: ${NUM_PATCHES} patches: ${LAST_HASH} to ${NEXT_HASH}" --allow-empty
git push
echo
echo "Done.  Zipped and mailed $NUM_PATCHES to oliver.hulett@gmail.com; from ${LAST_HASH} to ${NEXT_HASH}.  Press any key to exit"
read -r -n1
