# UsefulScripts

Scripts I've created for my own use.

## Scripts

- `BIAY_ScreenCaps.sh`
- `bible.awk`
- `dailybiblereading.sh`
- `gedit_getbible.sh`
- `generate_typst_fonts.sh`
- `getbible.sh`
- `getquran.sh`
- `kate_getbible.sh`
- `temp-alert.sh` + `temp-alert.desktop` — CPU temperature watcher (see below)

## temp-alert — CPU temperature watcher

Watches CPU temperature and pops a desktop alert when it climbs. Built for a refurb Dell Precision 7550 (Ubuntu Studio / KDE Plasma) whose fans sometimes fail to spin up as it warms, which once caused a thermal shutdown.

- Warns at 85 °C ("getting hot — check the fans") and at 95 °C ("save your work now").
- Checks once a minute; alerts at most once per 10 minutes per level.
- Reports fan speed when readable, and notes when no fan speed is reported.
- No root needed, no cron needed.

### Install

```sh
mkdir -p ~/bin ~/.config/autostart
cp temp-alert.sh ~/bin/temp-alert.sh
cp temp-alert.desktop ~/.config/autostart/temp-alert.desktop
chmod +x ~/bin/temp-alert.sh
```

Log out and back in (or start it now with `~/bin/temp-alert.sh &`). Test the popup any time with `~/bin/temp-alert.sh --test`.
