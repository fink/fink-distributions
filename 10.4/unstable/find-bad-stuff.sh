#!/bin/sh

FINKROOT="`dirname $0`/../../.."
FINKROOT=`cd $FINKROOT; pwd`

if [ -z "$1" ]; then
	echo "usage: $0 <bad_string> [search_path]"
	exit 1
fi

BAD_STRING="$1"; shift
SEARCH_PATH="$1"; shift
[ -z "$SEARCH_PATH" ] && SEARCH_PATH="$FINKROOT"

find "$SEARCH_PATH" "$@" -type f | grep -v -E '\.(sh|pl)$' | while read FILE; do
	if [ `file "$FILE" | grep -c Mach` -gt 0 ]; then
		otool -L "$FILE" | while read LINE; do
			if [ `echo "$LINE" | grep -c -E "$BAD_STRING"` -gt 0 ]; then
				echo "$FILE"
				break
			fi
		done
	fi
#done
done | sort -u | xargs dpkg -S | cut -d: -f1 | sort -u | less
