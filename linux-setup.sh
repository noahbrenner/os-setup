

# References:
# general
# https://sites.google.com/site/easylinuxtipsproject/mint
# for after os installation
# https://sites.google.com/site/easylinuxtipsproject/first-mint-xfce
# run browsers in the sandbox
# https://sites.google.com/site/easylinuxtipsproject/sandbox
# speed up the computer (perceived speed)
# https://sites.google.com/site/easylinuxtipsproject/3


# Always install recommended package dependencies
# Synaptic Package Manager: Settings > Preferences > "General" tab
# "Marking Changes" section: select "Consider recommended packages as dependencies"
# sudo sed -i 's/false/true/g' /etc/apt/apt.conf.d/00recommends


# Make terminal window opaque
# Terminal: Edit > Preferences > "Appearance" tab
# Background: select "None (use solid color)"


# Enable batter icon in system tray for laptops
# (test for/ask if computer is a laptop)
# Power Manager: select "Show system tray icon"


# Decrease swap use, improve RAM use
# (untested, but something like:)
# (test for memory < 4 GB)
# sudo "# Decrease swap usage to a more reasonable level" >> /etc/sysctl.conf
# sudo "vm.swappiness=10" >> /etc/sysctl.conf
# (test for memory > 1 GB)
# sudo "# Improve cache management" >> /etc/sysctl.conf
# sudo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
# reboot the computer
# check: `cat /proc/sys/vm/swappiness` should output `10`


# Enable Uncomplicated Firewall
sudo ufw enable
# check: `sudo ufw status verbose`


# Remove programs
sudo apt remove \
  gnome-orca \
  mono-runtime-common
# gnome-orca: screen reader
# mono-runtime-common: .NET implementation


# Install git
# TODO remove the following command if this file is fetched from git (it will eventually)
sudo apt install git

# Install programs
sudo apt install \
  firejail \
  vim-gtk3 \
  vlc

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim \
  && vim +PlugInstall +qall

# if 32 bit processor
sudo apt install chromium-browser
# else get chrome somehow
# end if


# Set up file(s) for custom firejail permissions
# They will persist when updating firejail
mkdir ~/.config/firejail
cp /etc/firejail/firefox.profile ~/.config/firejail
cp /etc/firejail/chromium.profile ~/.config/firejail
cp /etc/firejail/chromium-browser.profile ~/.config/firejail


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
sudo mv /etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla /
# undo: just move it back


# vim: shiftwidth=2
