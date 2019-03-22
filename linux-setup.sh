#!/bin/bash

# Run this script using `sudo`

# TODO Make sure these are installed (some might be bundled with others)
# - xelatex
#   - https://tex.stackexchange.com/questions/179778/xelatex-under-ubuntu
#   - XeLatex is a part of `texlive-xetex` package.
#     To install, run the following command: `sudo apt-get install texlive-xetex`
# - chktex
# - lacheck
# - ? other linters that `ale` (vim plugin) can use

# TODO check this file for default programs: /etc/gnome/defaults.list

# Exit if not running as root (if the Effective User ID is not 0)
if [[ $EUID -ne 0 ]]; then
  echo This file must be run using sudo. Exiting.
  exit
fi

# get user name
thisuser=$(logname)


# test if computer is a laptop
# TODO test this logic
echo -n "This script is being run on a "

case $(ls -d /home/*/ | head -n 1 | sed 's,/^home/,,' | sed 's,/$,,') in
  Laptop|Notebook|Portable|Sub Notebook)
    islaptop='true'
    echo laptop.
    ;;
  *)
    islaptop='false'
    echo desktop. # assumption
    ;;
esac



# Make keyboard cooperate after waking computer from suspend
# https://forums.linuxmint.com/viewtopic.php?t=152185
# https://wiki.fogproject.org/wiki/index.php?title=Kernel_Parameters
# (test for directory /sys/bus/platform/drivers/i8042 before running)
sed -i \
  's/\(GRUB_CMDLINE_LINUX_DEFAULT=".*\)"/\1 atkbd.reset i8042.nomux i8042.reset i8042.dumbkbd"/' \
  /etc/default/grub
# (check that it updated successfully)
update-grub
# (reboot needed, but that can be at the end of this script file)


# Always install recommended package dependencies
sed -i 's/\(Install-Recommends "\)[0-9]"/\11"/' /root/.synaptic/synaptic.conf
# ^OR> Synaptic Package Manager: Settings > Preferences > "General" tab
# "Marking Changes" section: select "Consider recommended packages as dependencies"
sed -i 's/false/true/g' /etc/apt/apt.conf.d/00recommends


# Make terminal window opaque
sudo -u $thisuser -- sed -i '/^BackgroundMode=/d' ~/.config/xfce4/terminal/terminalrc
# ^OR> Terminal: Edit > Preferences > "Appearance" tab
# Background: select "None (use solid color)"


# Set ComposeKey to Menu key
sed -i 's/^\(XKBOPTIONS="\)[^"]*"$/\1compose:menu"/' /etc/default/keyboard
# Info on possible settings: `man keyboard` & /usr/share/X11/xkb/rules/xorg.lst
# All possible characters: /usr/share/X11/locale/en_US.UTF-8/Compose


# Enable battery icon in system tray for laptops
# (test for/ask if computer is a laptop)
if [ "$islaptop" = "true" ]; then
  # TODO implement this
  # show battery icon in system tray
fi
# Power Manager: select "Show system tray icon"


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

# Remove programs
toRemove=(
  gnome-orca # screen reader
  mono-runtime-common # .NET implementation
)

apt-get purge --autoremove ${toRemove[@]}


# Install programs
toInstall=(
  # at # Schedule a one-time command to run later
  curl
  encfs # encrypted virtual filesystem
  ffmpeg # transcode audio and video files
  firejail # sandbox, particularly useful for firefox
  flac # TODO decide on this
  git
  libhal1-flash # enables playing DRM flash content in Firefox
  libimage-exiftool-perl # provides exiftool
  build-essential # C libraries, needed to compile sc-im
  libncurses5-dev # needed to compile (and run?) sc-im
  libncursesw5-dev # needed to compile (and run?) sc-im
  # linkchecker # TODO decide on this (check websites for broken links)
  nmap # provides ncat for testing HTTP requests and responses
  pdftk
  # python-pip # For Python 2
  python3-pip python3-venv # Both needed for pipenv
  python3-tk # tkinter for Python3
  sc # "spreadsheet calculator" (or do I want to install sc-im [manually]?)
  traceroute # trace the path of ip packets
  tree # display directories in a tree structure
  vim-gtk3 # Also uses Python 3 rather than 2
  vlc # vlc media player
  # wine # TODO decide on this
  zopfli # gzip compressor, but accomplishes better compression than `gzip`
)
# TODO Other programs I'll likely add:
# - idle
# - idle3

# TODO Programs to check out
# - cherrytree - hierarchical note taking application
# - treesheets - Data organizer that covers spreadsheets, mind mappers, and small databases
# - ytree - A file manager for terminals

# TODO decide between these media players
# toInstall+=(rhythmbox) # now the default on Linux Mint, has iPod compatibility
# toInstall+=(gmusicbrowser) # recommended by users, incl. users of MediaMonkey

# if 32 bit processor
toInstall+=(chromium-browser)
# else get chrome somehow
# end if

# if Linux Mint
toInstall+=(mint-meta-codecs)

apt-get install --install-recommends ${toInstall[@]} # TODO is recommends needed?


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
sudo -u $thisuser -- mkdir ~/pdfsizeopt && cd $_ \
  && curl -Lo pdfsizeopt.tar.gz https://github.com/pts/pdfsizeopt/releases/download/2017-01-24/pdfsizeopt_libexec_extraimgopt_linux-v3.tar.gz \
  && tar  xzvf pdfsizeopt.tar.gz && rm -f $_ \
  && curl -Lo pdfsizeopt \
  https://raw.githubusercontent.com/pts/pdfsizeopt/master/pdfsizeopt.single \
  && chmod +x pdfsizeopt


# TODO
# Install sc-im


# Install vim-plug
sudo -u $thisuser -- curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
  && vim +PlugInstall +qall

# Install nvm (Node Version Manager) -- https://github.com/creationix/nvm
sudo -u $thisuser -- curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
# Set environment variables so we can use nvm without restarting the shell
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
# Install nodejs
sudo -u $thisuser -- nvm install node

# Set up file(s) for custom firejail permissions
# They will persist when updating firejail
sudo -u $thisuser -- mkdir ~/.config/firejail
sudo -u $thisuser -- cp /etc/firejail/firefox.profile ~/.config/firejail
sudo -u $thisuser -- cp /etc/firejail/chromium.profile ~/.config/firejail
sudo -u $thisuser -- cp /etc/firejail/chromium-browser.profile ~/.config/firejail


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


# Adjust mouse pointer speed
# Mouse and Touchpad > Pointer speed: 3 or 4

# Disable hibernation
mv /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla /
# undo: just move it back


# Change settings for clock
# ~/.config/xfce4/panel/datetime-5.rc


# vim: shiftwidth=2
