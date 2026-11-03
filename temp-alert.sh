#!/bin/bash
# temp-alert.sh — watches CPU temperature and pops a desktop alert when it climbs.
# Built for Scott's refurb Dell Precision 7550 (Ubuntu Studio / KDE Plasma),
# whose fans sometimes fail to spin up as it warms.
#
# Run it in your KDE session (see temp-alert.desktop for autostart). It checks
# once a minute, forever. No root needed, no cron needed.
#
#   WARN at 85 C:  "getting hot — check the fans"
#   CRIT at 95 C:  "save your work now"
# Alerts at most once per 10 minutes per level, so it nags but doesn't spam.
# Test it any time with:  temp-alert.sh --test

WARN=85
CRIT=95
COOLDOWN=600  # seconds between repeat alerts at the same level
STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/temp-alert"
mkdir -p "$STATE_DIR" 2>/dev/null

notify() {  # $1 = title, $2 = body
    notify-send -u critical -t 0 "$1" "$2" 2>/dev/null \
        || kdialog --sorry "$1
$2" 2>/dev/null \
        || echo "TEMP ALERT: $1 - $2" >&2
}

if [ "$1" = "--test" ]; then
    notify "CPU hot: 88 C (test)" "This is a test of the temperature alert. Fans may not have spun up — save your work and check the fans."
    exit 0
fi

while true; do
    # Highest temperature across all thermal zones (millidegrees -> whole C)
    MAX=0
    for f in /sys/class/thermal/thermal_zone*/temp; do
        [ -r "$f" ] || continue
        t=$(( $(cat "$f") / 1000 ))
        [ "$t" -gt "$MAX" ] && MAX=$t
    done

    if [ "$MAX" -gt 0 ]; then
        # Best-effort fan check: highest reported fan speed (RPM)
        FAN=0
        for f in /sys/class/hwmon/hwmon*/fan*_input; do
            [ -r "$f" ] || continue
            r=$(cat "$f" 2>/dev/null)
            [ "${r:-0}" -gt "$FAN" ] && FAN=$r
        done

        if [ "$FAN" -eq 0 ]; then
            FAN_NOTE="No fan speed reported — the fans may not have spun up."
        else
            FAN_NOTE="Fans at ${FAN} RPM."
        fi

        now=$(date +%s)
        if [ "$MAX" -ge "$CRIT" ]; then
            LEVEL=crit; TITLE="CPU critically hot: ${MAX} C"; BODY="Save your work NOW — shutdown is near. ${FAN_NOTE}"
        elif [ "$MAX" -ge "$WARN" ]; then
            LEVEL=warn; TITLE="CPU hot: ${MAX} C"; BODY="Temperature is climbing. ${FAN_NOTE}"
        else
            LEVEL=""
        fi

        if [ -n "$LEVEL" ]; then
            stamp="$STATE_DIR/$LEVEL"
            last=$(cat "$stamp" 2>/dev/null || echo 0)
            if [ $((now - last)) -ge $COOLDOWN ]; then
                echo "$now" > "$stamp"
                notify "$TITLE" "$BODY"
            fi
        fi
    fi

    sleep 60
done
