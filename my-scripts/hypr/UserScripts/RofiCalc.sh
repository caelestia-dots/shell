#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */
# /* Calculator (using qalculate) and rofi */
# /* Submitted by: https://github.com/JosephArmas */

rofi_theme="$HOME/.config/rofi/config-calc.rasi"

# Kill Rofi if already running before execution
if pgrep -x "rofi" >/dev/null; then
    pkill rofi
fi

# main function

while true; do
    result=$(
        rofi -i -dmenu \
            -config $rofi_theme \
            -mesg "$result      =    $calc_result"
    )

    if [ $? -ne 0 ]; then
        exit
    fi

    if [ -n "$result" ]; then
        calc_result=$(qalc -t "$result")
        echo "$calc_result" | wl-copy
    fi
done
