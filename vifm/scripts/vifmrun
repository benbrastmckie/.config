#!/bin/sh

if [ -z "$(command -v vifm)" ]; then
	printf "vifm isn't installed on your system!\n"
	exit 1
elif [ -z "$(command -v ueberzug)" ]; then
	exec vifm "$@"
else
	cleanup() {
		exec 3>&-
	    rm "$FIFO_UEBERZUG"
	}
	[ ! -d "$HOME/.cache/vifm" ] && mkdir -p "$HOME/.cache/vifm"
	export FIFO_UEBERZUG="$HOME/.cache/vifm/ueberzug-${$}"
	mkfifo "$FIFO_UEBERZUG"
	ueberzug layer -s <"$FIFO_UEBERZUG" -p json &
	exec 3>"$FIFO_UEBERZUG"
	trap cleanup EXIT
	vifm "$@" 3>&-
	vifmimg clear
fi
