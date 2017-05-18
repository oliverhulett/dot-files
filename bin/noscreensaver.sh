#!/bin/bash
## Needs to be a script, not an alias or a function, because the media user needs to run it.

export DISPLAY=:0;
gsettings set org.gnome.settings-daemon.plugins.power active false;
gsettings set org.gnome.desktop.screensaver idle-activation-enabled false;
gsettings set org.gnome.desktop.session idle-delay 0;
xset -dpms;
xset s off;
xset s noblank

