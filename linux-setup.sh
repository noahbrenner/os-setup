#!/bin/bash

# Require this script to be run as root with $SUDO_USER defined
if ! ([[ $(whoami) == 'root' ]] && [[ -v 'SUDO_USER' ]]); then
  >&2 echo 'This script must be run using "sudo". Exiting...'
  exit 1
fi


# Determine whether this script is being run on a laptop
case $(dmidecode --string chassis-type) in
  'Laptop'|'Notebook'|'Portable'|'Sub Notebook')
    is_laptop='true' ;;
  *)
    is_laptop='false' ;;
esac


# === Fix home directory permissions === #

# Set home directories to be readable only by their owners
chmod 700 /home/*

# Configure `adduser` to do the same for users created later
file='/etc/adduser.conf'
[[ -f "$file" ]] && sed -i 's/^DIR_MODE=[0-7]*/DIR_MODE=0700/' "$file"
unset -v file


# Make terminal window opaque
sudo -u $SUDO_USER -- sed -i '/^BackgroundMode=/d' ~/.config/xfce4/terminal/terminalrc
# ^OR> Terminal: Edit > Preferences > "Appearance" tab
# Background: select "None (use solid color)"


# === Set ComposeKey to Menu key === #

# Info on possible settings:
# - `man keyboard`
# - /usr/share/X11/xkb/rules/xorg.lst

# All possible composed characters:
# - /usr/share/X11/locale/en_US.UTF-8/Compose

# NOTE: This change won't take effect until the next login
file='/etc/default/keyboard'
[[ -f "$file" ]] && sed -i 's/^XKBOPTIONS=.*$/XKBOPTIONS="compose:menu"/' "$file"
unset -v file


# Enable battery icon in system tray for laptops
if [[ "$is_laptop" == 'true' ]]; then
  : # TODO implement this
fi


# Decrease swap use, improve RAM use
# (untested, but something like:)
# (test for memory < 4 GB)
# echo "# Decrease swap usage to a more reasonable level" >> /etc/sysctl.conf
# echo "vm.swappiness=10" >> /etc/sysctl.conf
# (test for memory > 1 GB)
# echo "# Improve cache management" >> /etc/sysctl.conf
# echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
# reboot the computer
# check: `cat /proc/sys/vm/swappiness` should output `10`


# Enable Uncomplicated Firewall
ufw enable
# check: `sudo ufw status verbose`

# === Install/Uninstall apt packages === #

# Any indented package is recommended by the unindented package above it

# Packages I'd probably want to install when trying out a live USB
install_minimum=(
  curl
  git
    gitk
  ntp
  vim-gtk3
    fonts-dejavu
  xcape # TODO: Maybe remove once I have a better setup for keyboard shortcuts
  xfpanel-switch
)

# Packages to install on my working computer, in addition to $install_minimum
install_main=(
  build-essential
  encfs # Encrypted virtual filesystem
  ffmpeg
  flac # TODO Was this the best one for compression?
  gimp
  inkscape
    libimage-magick-perl
    python-lxml
    python-numpy
    python-scour
  libimage-exiftool-perl # Provides exiftool
  lilypond
  nmap # Provides ncat for testing HTTP requests and responses
  # pdftk # Used to be in apt, but not currently -- probably install as snap
  python3
    idle # Or could be idle3, but both are for python3 at this point
    python3-pip
    python3-tk
    python3-venv # Also required for pipenv
  texlive-xetex
    lmodern
  traceroute
  tree
  vlc
    libdvd-pkg # This worked to play DVDs in VLC, but not in Parole
  zopfli

  # Syntax checkers used in vim via ALE
  # TODO Check for more to add to this section
  chktex
  lacheck
)

# if 32 bit processor
install_main+=(chromium-browser)
# else get chrome somehow
# end if

# if Linux Mint
install_main+=(mint-meta-codecs)

# Packages I haven't yet decided on
install_maybe=(
  at # Schedule a one-time command to run later
  firejail # Sandbox, particularly useful for firefox
  libavcodec-extra # From ubuntu-restricted-extras; Still no DVD playback, reboot?
  libncurses5-dev # Needed to compile (and run?) sc-im
  libncursesw5-dev # Needed to compile (and run?) sc-im
  libhal1-flash # Only needed for Firefox to play DRM flash content
  linkchecker # Check websites for broken links
  python
    idle-python2.7
    python-pip
    python-tk
    python-venv
  sc # TODO: This or sc-im? sc-im needs build-essential, libncurses{w,}5-dev
  shellcheck # Syntax checker for shell scripts. Used by ALE
  wine
  ytree # A file manager for terminals

  # Organization
  cherrytree # Hierarchical note-taking application
  treesheets # Data organizer; covers spreadsheets, mind mappers, & small databases

  # Media players
  gmusicbrowser # Recommended by users, including users of MediaMonkey
  rhythmox # The default on Linux Mint; iPod compatibility, iTunes-inspired
)

# Full list of packages to install
to_install=(
  "${install_minimum[@]}"
  "${install_main[@]}"
  # "${install_maybe[@]}"
)

# Packages I don't want which may have been installed by default
# NOTE: Default programs are listed here: /etc/gnome/defaults.list
to_uninstall=(
  vim-tiny

  # Linux Mint default packages
  gnome-orca # Screen reader
  mono-runtime-common # .NET implementation
)

apt-get update
apt-get --yes upgrade
# This could use --install-recommends if I don't want to curate Recommends
apt-get install --yes ${to_install[@]}
apt-get purge --yes --autoremove ${to_uninstall[@]}
unset -v install_minimum install_main install_maybe to_install to_uninstall

# This is needed so that libdvd-pkg can install updates from source
# The execution of this command requires human interaction
dpkg-reconfigure libdvd-pkg


# Install pdfsizeopt - https://github.com/pts/pdfsizeopt
# NOTE Check for new versions, since the version is hard-coded in the URL
# TODO Do this in a subshell so that the working directory doesn't change
# TODO Try installing dependencies separately, rather than downloading them from the repo
# (without the optional dependencies, use the argument: --do-require-image-optimizers=no
# - advpng
# - ECT
# - optipng
# - zopflipng
# - jbig (optional)
# - pngout (optional)
# TODO Add ~/pdfsizeopt to PATH
# TODO Install pdftk and write a bash version of pdfcompress function
sudo -u $SUDO_USER -- mkdir ~/pdfsizeopt && cd $_ \
  && curl -Lo pdfsizeopt.tar.gz https://github.com/pts/pdfsizeopt/releases/download/2017-01-24/pdfsizeopt_libexec_extraimgopt_linux-v3.tar.gz \
  && tar  xzvf pdfsizeopt.tar.gz && rm -f $_ \
  && curl -Lo pdfsizeopt \
  https://raw.githubusercontent.com/pts/pdfsizeopt/master/pdfsizeopt.single \
  && chmod +x pdfsizeopt


# TODO
# Install sc-im


# Install nvm (Node Version Manager) -- https://github.com/creationix/nvm
sudo -u $SUDO_USER -- curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
# Set environment variables so we can use nvm without restarting the shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# Install nodejs
sudo -u $SUDO_USER -- nvm install node

# Set up file(s) for custom firejail permissions
# They will persist when updating firejail
sudo -u $SUDO_USER -- mkdir ~/.config/firejail
sudo -u $SUDO_USER -- cp /etc/firejail/firefox.profile ~/.config/firejail
sudo -u $SUDO_USER -- cp /etc/firejail/chromium.profile ~/.config/firejail
sudo -u $SUDO_USER -- cp /etc/firejail/chromium-browser.profile ~/.config/firejail


# Always run in the firejail sandbox
## cp /usr/share/applications/firefox.desktop ~/.local/share/applications
## cp /usr/share/applications/chromium-browser.desktop ~/.local/share/applications
## sed -i 's/Exec=firefox/Exec=firejail firefox/g' ~/.local/share/applications/firefox.desktop
## sed -i 's/Exec=chromium-browser/Exec=firejail chromium-browser/g' ~/.local/share/applications/chromium-browser.desktop
# undo: rm ~/.local/share/applications/firefox.desktop
# undo: rm ~/.local/share/applications/chromium-browser.desktop

# Run browsers in the sandbox when started from taskbar launchers
# right-click browser icon > Properties > edit (pencil icon)
# Command: prepend "firejail "


# Disable hibernation
mv /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla /
# undo: just move it back


# Change settings for clock
# ~/.config/xfce4/panel/datetime-5.rc


# vim: shiftwidth=2
