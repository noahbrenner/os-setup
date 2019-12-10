#!/bin/bash

# Require this script to be run as root with $SUDO_USER defined
if ! ([[ "$(whoami)" == 'root' ]] && [[ -v 'SUDO_USER' ]]); then
  >&2 echo 'This script must be run using "sudo". Exiting...'
  exit 1
fi


# === Platform detection === #

# Boolean logic: https://stackoverflow.com/questions/2953646/how-to-declare-and-use-boolean-variables-in-shell-script

# Is this a 32-bit OS?
# - https://www.cyberciti.biz/faq/linux-how-to-find-if-processor-is-64-bit-or-not/
[[ "$(getconf LONG_BIT)" == '32' ]] && is_32_bit=1

# Is this a laptop?
# - https://unix.stackexchange.com/questions/111508/bash-test-if-word-is-in-set
chassis=$(dmidecode --string chassis-type)
[[ $chassis =~ ^(Laptop|Notebook|Portable|Sub Notebook) ]] && is_laptop=1
unset -v chassis

# Get the OS distro name
# Likely values: 'Ubuntu', 'LinuxMint'
distro=$(lsb_release --id --short)

# === Fix home directory permissions === #

# Set home directories to be readable only by their owners
chmod 700 /home/*

# Configure `adduser` to do the same for users created later
file='/etc/adduser.conf'
[[ -f "$file" ]] && sed -i 's/^DIR_MODE=[0-7]*/DIR_MODE=0700/' "$file"
unset -v file


# === Make terminal window opaque === #

# If the config file has a "BackgroundMode" line, delete it
file="/home/$SUDO_USER/.config/xfce4/terminal/terminalrc"
[[ -f "$file" ]] && sudo -u $SUDO_USER -- sed -i '/^BackgroundMode=/d' "$file"
unset -v file


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


# === Enable battery icon in system tray for laptops === #

if (( $is_laptop )); then
  : # TODO implement this
fi


# === Decrease swap use, improve RAM use === #

# (untested, but something like:)
# (test for memory < 4 GB)
# echo "# Decrease swap usage to a more reasonable level" >> /etc/sysctl.conf
# echo "vm.swappiness=10" >> /etc/sysctl.conf
# (test for memory > 1 GB)
# echo "# Improve cache management" >> /etc/sysctl.conf
# echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
# Reboot the computer
# Check: `cat /proc/sys/vm/swappiness` should output `10`


# === Increase the max number of files which can be watched === #

# https://stackoverflow.com/a/24994331
# https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers

# The default on my computer when writing this was 8192
echo fs.inotify.max_user_watches=65536 >> /etc/sysctl.conf
sysctl --system


# === Enable Uncomplicated Firewall === #

ufw enable
# Check: `sudo ufw status verbose`


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

if (( $is_32_bit )); then
  install_main+=(chromium-browser)
else
  : # TODO Install Chrome somehow
fi

if [[ "$distro" == 'LinuxMint' ]]; then
  install_main+=(mint-meta-codecs)
fi

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
apt-get install --yes "${to_install[@]}"
apt-get purge --yes --autoremove "${to_uninstall[@]}"
unset -v install_minimum install_main install_maybe to_install to_uninstall

# This is needed so that libdvd-pkg can install updates from source
# The execution of this command requires human interaction
dpkg-reconfigure libdvd-pkg


# === Install pdfsizeopt === #

# Repo: https://github.com/pts/pdfsizeopt
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


# === Install Node.js via nvm === #

# nvm (Node Version Manager): https://github.com/creationix/nvm

# Currently, we have to specify a specific version of nvm to install. The nvm
# developer does intend to eventually implement the ability to upgrade itself,
# which will make this process cleaner. Until then, we should check for new
# versions before installing.

nvm_ver='v0.34.0' # TODO Update this as needed (until `upgrade` is implemented)
src_url="https://raw.githubusercontent.com/creationix/nvm/$nvm_ver/install.sh"

# Install nvm
curl -o- "$src_url" | sudo -u "$SUDO_USER" -- bash

# Load nvm and install Node.js as $SUDO_USER
su "$SUDO_USER" --login <<'EOF'
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm install node
EOF

# TODO Install global npm packages

unset -v nvm_ver src_url


# === Configure firejail === #

# Set up file(s) for custom firejail permissions
# They will persist when updating firejail
# TODO FIXME Run these in a subshell or replace "~" with "/home/$SUDO_USER"
sudo -u "$SUDO_USER" -- mkdir ~/.config/firejail
sudo -u "$SUDO_USER" -- cp /etc/firejail/firefox.profile ~/.config/firejail
sudo -u "$SUDO_USER" -- cp /etc/firejail/chromium.profile ~/.config/firejail
sudo -u "$SUDO_USER" -- cp /etc/firejail/chromium-browser.profile ~/.config/firejail

# Always run in the firejail sandbox
## cp /usr/share/applications/firefox.desktop ~/.local/share/applications
## cp /usr/share/applications/chromium-browser.desktop ~/.local/share/applications
## sed -i 's/Exec=firefox/Exec=firejail firefox/g' ~/.local/share/applications/firefox.desktop
## sed -i 's/Exec=chromium-browser/Exec=firejail chromium-browser/g' ~/.local/share/applications/chromium-browser.desktop
# Undo: rm ~/.local/share/applications/firefox.desktop
# Undo: rm ~/.local/share/applications/chromium-browser.desktop

# Run browsers in the sandbox when started from taskbar launchers
# Right-click browser icon > Properties > edit (pencil icon)
# Command: Prepend with "firejail "


# === Disable hibernation === #

mv /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla /
# Undo: Just move it back


# === Change settings for clock === #

# ~/.config/xfce4/panel/datetime-5.rc


# vim: shiftwidth=2
