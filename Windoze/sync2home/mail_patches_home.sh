#!/bin/bash

MAILER="C:/Users/olihul/things/mailsend1.19.exe/mailsend1.19.exe"
ZIPPER="C:/Program Files/7-Zip/7z.exe"
HERE="$(dirname "$0")"
HASH_FILE="${HERE}/.last-mailed-hash"

cd "${HERE}"
git pullb

TODAY="$(date '+%Y-%m-%d')"
LAST_HASH="$(sed -ne '1p' "${HASH_FILE}")"
NEXT_HASH="$(git rev-parse HEAD)"
echo "Syncing from ${LAST_HASH} to ${NEXT_HASH}"

PATCHES_ROOT="${TODAY}.dotfiles"
ZIPFILE="${PATCHES_ROOT}.7z"
rm -rf "${PATCHES_ROOT}" "${ZIPFILE}" 2>/dev/null
mkdir "${PATCHES_ROOT}"

NUM_PATCHES=0
echo "Using list files: " files.*
for f in files.*; do
	d="$(echo $f | sed -re 's/^files.//')"
	mkdir "${PATCHES_ROOT}/$d" 2>/dev/null
	echo "Formatting patches from ${LAST_HASH} for $f"
	fmt_cmd="git format-patch --output-directory=${PATCHES_ROOT}/$d --no-binary --attach --to oliver.hulett@gmail.com ${LAST_HASH} -- $(cat $f | xargs)"
	echo $fmt_cmd
	np=$($fmt_cmd | wc -l)
	NUM_PATCHES=$(( $NUM_PATCHES + $np ))
done
if [ $NUM_PATCHES == 0 ]; then
	echo "No patches formatted, not sending e-mail"
	exit 0
fi

echo "Zipping $NUM_PATCHES patches"
echo "${ZIPPER}" a "${ZIPFILE}" "${PATCHES_ROOT}"
"${ZIPPER}" a "${ZIPFILE}" "${PATCHES_ROOT}"

echo "Mailing $NUM_PATCHES patches"
echo "${MAILER}" -smtp unixmail.comp.optiver.com -f olihul@optiver.com.au -t oliver.hulett@gmail.com -sub "${TODAY} dotfiles" -attach "${ZIPFILE}",application/x-7z-compressed,a
"${MAILER}" -smtp unixmail.comp.optiver.com -f olihul@optiver.com.au -t oliver.hulett@gmail.com -sub "${TODAY} dotfiles" -attach "${ZIPFILE}",application/x-7z-compressed,a
echo "Removing $PATCHES_ROOT and $ZIPFILE"
rm -rf "${PATCHES_ROOT}" "${ZIPFILE}" 2>/dev/null

echo "Committing last mailed hash: ${NEXT_HASH}"
echo ${NEXT_HASH} >"${HASH_FILE}"
git commit .last-mailed-hash -m"Sync2Home autocommit: ${NUM_PATCHES} patches: ${LAST_HASH} to ${NEXT_HASH}" --allow-empty
git push