#!/usr/bin/env sh

cat ~/.local/state/caelestia/sequences.txt 2>/dev/null

COMMAND="$@"

if [ "$1" = "ghostty" ]; then
	exec ghostty -e ${COMMAND#*ghostty }
fi

if [ "$1" = "alacritty" ]; then
	exec alacritty -e ${COMMAND#*alacritty }
fi

if [ "$1" = "konsole" ]; then
	exec konsole -e ${COMMAND#*konsole }
fi

if [ "$1" = "xterm" ]; then
	exec xterm -e ${COMMAND#*xterm }
fi


exec $COMMAND
