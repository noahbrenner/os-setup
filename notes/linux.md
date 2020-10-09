Dev notes for GNU/Linux setup
=============================

REFERENCES
----------

* General
    - https://sites.google.com/site/easylinuxtipsproject/mint

* For after os installation
    - https://sites.google.com/site/easylinuxtipsproject/first-mint-xfce

* Run browsers in the sandbox
    - https://sites.google.com/site/easylinuxtipsproject/sandbox

* Speed up the computer (perceived speed)
    - https://sites.google.com/site/easylinuxtipsproject/3

* Test for laptop vs. desktop
    - http://superuser.com/questions/877677/programatically-determine-if-an-script-is-being-executed-on-laptop-or-desktop

* Run multiple bash commands as another user
    - https://stackoverflow.com/questions/17758235/how-to-execute-a-group-of-commands-as-another-user-in-bash

Info from other distros (esp. Mint)
-----------------------------------

* Dependencies/Recommends of `mint-meta-codecs`
  + The "Install Multimedia Codecs" launcher runs:
    - `$ apturl apt://mint-meta-codecs?refresh=yes`
  - adobe-flashplugin
  - cabextract
  - chromium-codecs-ffmpeg-extra
  - gstreamer1.0-libav
  - gstreamer1.0-plugins-bad
  - gstreamer1.0-plugins-ugly
  - gstreamer1.0-vaapi
  - libavcodec-extra
  - libdvdcss2
  - libdvdnav4
  - libdvdread4
  - libhal1-flash
  - unrar
  - unshield
  - vlc
  - vlc-l10n
  - vlc-plugin-notify
* Configuration for `xfpanel`
  - Display
    - Measurements
      - Row Size: 32
      - Automaticaly increase the length: true
* Is `xfpanel-switch` installed by default?
  - No
* Backup software
  - mintbackup (so, specific to Linux Mint)
* Document viewer
  - Xreader
* Terminal
  - xfce4-terminal
  - "Monospace Regular" size 10
  - Text blinks: Always
* When playing a DVD with Xplayer, it asked to install:
  - gstreamer1.0-plugins-bad
    - ...in order to get MPEG-2 System Stream demuxer
    - This still didn't work for Xplayer, though VLC probably works
* Notable installed programs
  - Image Viewer: Xviewer
  - Image Viewer/organizer: Pix
  - Media Player: Xplayer
  - Music player/organizer: Rhythmbox
  - Color temperature adjustment tool: Redshift
  - Disk Usage Analyzer: Baobab
  - System Restore Utility: Timeshift

Setting Keyboard Shortcuts
--------------------------

It might work to use xfconf for shortcut keys

* "Settings Editor" (or "Keyboard") for a GUI
* `xfconf-query` (only keydown) for a CLI
* `xcape` when I need keyup shortcuts (probably just the one, `<Super>`, though)

Sample Query:

```bash
# To list the properties of a channel or subproperties, include `--list`
$ xfconf-query \
  --channel xfce4-keyboard-shortcuts \
  --property '/commands/custom/<Primary><Alt>t'
# => exo-open --launch TerminalEmulator
```

Sample Setting (not tested yet)

```bash
# This only changes the value of an existing property.
# For a new shortcut, we'll likely need `--create/-n` and `--type/-t`
$ xfconf-query \
  --channel xfce4-keyboard-shortcuts \
  --property '/commands/custom/<Primary><Alt>t'
  --set 'exo-open --launch TerminalEmulator'
```
