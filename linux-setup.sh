#!/bin/bash

set -euo pipefail

# Require this script to be run as root with $SUDO_USER defined
if ! ([[ "$(whoami)" == 'root' ]] && [[ -v 'SUDO_USER' ]]); then
	>&2 echo 'This script must be run using "sudo". Exiting...'
	exit 1
fi


# === Config settings & Platform detection === # {{{1

# The following variables are meant to be modified by functions defined later in
# order to dynamically generate the set of tasks that need to be executed.  At
# the bottom of this file, those functions are called and then these
# configuration variables are acted upon.

# TODO Rename to run_after_install or add separate array with that name
# Arrays of function names to be called at specific points
# Naming convention for added functions: __do_<task>
run_before_apt_install=()
run_after_apt_install=()


# These are just default values, some of them might be updated by running
# `update_config` (declared below).  This structure simplifies debugging:
# Just set alternate values here and comment out the call to `update_config`.

# Reference for boolean logic in bash:
# https://stackoverflow.com/questions/2953646/how-to-declare-and-use-boolean-variables-in-shell-script

is_32_bit=0
is_laptop=0
distro=''

update_config() {
	# https://www.cyberciti.biz/faq/linux-how-to-find-if-processor-is-64-bit-or-not/
	if [[ "$(getconf LONG_BIT)" == '32' ]]; then
		is_32_bit=1
	fi

	# https://unix.stackexchange.com/questions/111508/bash-test-if-word-is-in-set
	local chassis=$(dmidecode --string chassis-type)
	if [[ $chassis =~ ^(Laptop|Notebook|Portable|Sub Notebook) ]]; then
		is_laptop=1
	fi

	# Likely values: 'Ubuntu', 'LinuxMint'
	distro=$(lsb_release --id --short)
}


# === High-touch variables === # {{{1

# These variables are meant to be modified by functions defined later in order
# to dynamically generate the set of tasks that need to be executed.  At the
# bottom of this file, those functions are called and then these configuration
# variables are acted upon.

# Arrays of function names to be called at specific points
# Naming convention for added functions: __do_<task>
run_before_apt_install=()
run_after_apt_install=()

# Dynamically generated array of extra packages/PPAs to install
# Function in the "Package installation: Custom" section can append to these
apt_ppa_repositories=()
apt_install_custom=()
snap_install_custom=()
snap_install_classic_custom=()
pipx_install_custom=()


# === Package installation: Package managers === # {{{1


## apt packages ## {{{2

install_apt_packages() {
	local repository

	for repository in "${#apt_ppa_repositories[@]}"; do
		add-apt-repository "$repository"
	done

	# Install apt packages
	apt-get-update
	apt-get --yes upgrade

	# TODO Install each set conditionally
	apt-get install --yes "${apt_install_minimum[@]}"
	apt-get install --yes "${apt_install_main[@]}"
	#apt-get install --yes "${apt_install_maybe[@]}"

	if (( "${#apt_install_custom[@]}" > 0 )); then
		apt-get install --yes "${apt_install_custom[@]}"
	fi

	apt-get purge --yes --autoremove "${apt_uninstall[@]}"
}

# Indented packages were selected to augment the unindented package above them

# Packages I'd probably want to install when trying out a live USB
apt_install_minimum=(
	curl
	git
		gitk
	ntp
	vim-gtk3
		fonts-dejavu
	xcape # TODO Maybe remove once I have a better setup for keyboard shortcuts
	xfpanel-switch # TODO Get this working or decide if I want to remove it
)

# Packages to install on my working computer, in addition to those above
apt_install_main=(
	audacity
	build-essential
	cmake
	encfs # Encrypted virtual filesystem
	ffmpeg
	flac
	flake
	gimp
	gnumeric
		gnumeric-plugins-extra
	inkscape
		libimage-magick-perl
		python-lxml
		python-numpy
		python-scour
	libimage-exiftool-perl # Provides exiftool
	# libreoffice # TODO Do I want everything, or do I want -core/-common instead?
		libreoffice-script-provider-python
	lilypond
	nmap # Provides ncat for testing HTTP requests and responses
	pandoc
	# pdftk # Used to be in apt, but not currently -- probably install as snap
	python3
		idle # Or could be idle3, but both are for python3 at this point
		python3-pip
		python3-tk
		python3-venv # Also required for pipenv
	snapd
	texlive-xetex
		lmodern
		texlive-fonts-extra
	tmux
	traceroute
	tree
	vlc
		libdvd-pkg # This worked to play DVDs in VLC, but not in Parole
		vlc-plugin-fluidsynth # Enables VLC to play MIDI files
	xdotool
	xournal # PDF editor - TODO Do I want xournal++ instead (PPA or snap)? Or okular?
	zopfli

	# Syntax checkers used in vim via ALE
	# TODO Check for more to add to this section
	chktex
	lacheck
)

# Packages I haven't yet decided on
apt_install_maybe=(
	at # Schedule a one-time command to run later
	firejail # Sandbox, particularly useful for firefox
	libavcodec-extra # From ubuntu-restricted-extras; Still no DVD playback, reboot?
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

# Packages I don't want which may have been installed by default
# NOTE: Default programs are listed here: /etc/gnome/defaults.list
apt_uninstall=(
	vim-tiny

	# Xubuntu default packages
	parole

	# Linux Mint default packages
	gnome-orca # Screen reader
	mono-runtime-common # .NET implementation
)


## snap packages ## {{{2

# http://www.linuxandubuntu.com/home/snap-vs-deb-package

install_snap_packages() {
	snap install "${snap_install[@]}"
	snap install --classic "${snap_install_classic[@]}"

	if (( "${#snap_install_custom[@]}" > 0 )); then
		snap install "${snap_install_custom[@]}"
	fi

	if (( "${#snap_install_classic_custom[@]}" > 0 )); then
		snap install --classic "${snap_install_classic_custom[@]}"
	fi
}

snap_install=(
	pdftk
	syncthing
)

snap_install_classic=(
	blender
	slack
)

## npm packages ## {{{2

install_npm_packages() {
	if (( "${#npm_install[@]}" > 0 )); then
		# TODO Test whether we need a login shell to get the correct PATH & ~/.npmrc
		sudo -u "$SUDO_USER" -- npm install --global "${npm_install[@]}"
	fi
}

npm_install=(
	js-beautify
	prettier
)

## pip packages ## {{{2

install_pipx_packages() {
	# https://github.com/pipxproject/pipx
	sudo -u "$SUDO_USER" -- python3 -m pip install --user pipx
	# sudo -u "$SUDO_USER" -- python3 -m pipx ensurepath # Is this needed?

	for package in "${pipx_install[@]}" "${pipx_install_custom[@]}"; do
		# TODO Fix this, we currently get "sudo: pipx: command not found"
		sudo -u "$SUDO_USER" -- pipx install "$package"
	done
}

pipx_install=(
	bpsproxy
	bpsrender
	docker-compose
	flake8 # Wrapper for pyflakes, pycodestyle, mccabe (circular complexity check)
		# Others to consider instead/in addition:
		# pycodestyle # Just PEP8
		# pylint # PEP8 & other checks
		# pydocstyle
	grip
	pipenv
)

# === Package installation: Custom === # {{{1


## Chrome/Chromium ## {{{2

install_chrome() {
	if (( "$is_32_bit" )); then
		apt_install_custom+=(chromium-browser)
	else
		: # TODO Install Chrome
	fi
}


## Media codecs ## {{{2

install_codecs() {
	if [[ "$distro" == 'LinuxMint' ]]; then
		apt_install_custom+=(mint-meta-codecs)
	fi
}


## Node.js ## {{{2

# Instal via nvm (Node Version Manager): https://github.com/creationix/nvm

install_node_js() {
	run_after_apt_install+=(__do_install_node_js)

	__do_install_node_js() {
		# Currently, we have to specify a specific version of nvm to install.  The nvm
		# developer does intend to eventually implement the ability for nvm to upgrade
		# itself, which will make this process cleaner. Until then, we should check for
		# new versions before installing.

		# TODO Update this as needed (until `upgrade` is implemented)
		local nvm_ver='v0.34.0'
		local src_url="https://raw.githubusercontent.com/creationix/nvm/$nvm_ver/install.sh"

		# Install nvm
		curl -o- "$src_url" | sudo -u "$SUDO_USER" -- bash

		# Load nvm and install Node.js as $SUDO_USER
		# TODO When adding to .profile, format nicer and test for [ -d DIR ]
		su "$SUDO_USER" --login <<-'EOF'
			export NVM_DIR="$HOME/.nvm"
			[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
			nvm install node

			# Configure a custom location for globally-installed packages
			mkdir "~/.npm-global"
			echo 'PATH="~/.npm-global/bin:$PATH"' >> $HOME/.profile
			npm config set prefix '~/.npm-global'
			npm install --global npm
		EOF
	}
}


## Go (Golang) ## {{{2

# Instal via gvm (Golang Version Manager): https://github.com/moovweb/gvm

install_golang() {
	run_after_apt_install+=(__do_install_golang)

	__do_install_golang() {
		su "$SUDO_USER" --login <<-'EOF'
			gvm_install_script="https://raw.githubusercontent.com/moovweb/gvm/master/binscripts/gvm-installer"

			# This script installs gvm and adds a line to ~/.bashrc which loads gvm
			bash < <(curl -s -S -L "$gvm_install_script")

			# Since we're not restarting the shell, we need to load gvm manualy
			source ~/.gvm/scripts/gvm

			# Install the latest stable Go version (not beta/rc) and enable it by default
			latest_go="$(gvm listall | tr -d ' ' | grep '^go[0-9.]*$' | tail -n 1)"
			nvm use "$latest_go" --default
		EOF
	}
}


## AWS CLI ## {{{2

install_aws_cli() {
	pipx_install_custom+=(awscli)
	run_after_apt_install+=(__do_install_aws_cli)

	__do_install_aws_cli() {
		: # TODO Add the following to .bashrc
		# if [ -x ~/.local/bin/aws_completer ]; then
		#     complete -C ~/.local/bin/aws_completer aws
		# fi
	}
}


## GitHub CLI ## {{{2

# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# NOTE: After installation, you'll still need to run `$ gh auth login`

install_github_cli() {
	apt-key adv --keyserver keyserver.ubuntu.com --recv-key C99B11DEB97541F0
	apt_ppa_repositories+=(https://cli.github.com/packages)
	apt_install_custom+=(gh)
}


## pdfsizeopt ## {{{2

# Repo: https://github.com/pts/pdfsizeopt

install_pdfsizeopt() {
	run_after_apt_install+=(__do_install_pdfsizeopt)

	__do_install_pdfsizeopt() {
		# TODO Check for new versions, since the version is hard-coded in the URL
		local version_date='2017-01-24'
		local version='v3'

		local download_base='https://github.com/pts/pdfsizeopt/releases/download'
		local raw_base='https://raw.githubusercontent.com/pts/pdfsizeopt/master'

		local core_archive="${version_date}/pdfsizeopt_libexec_linux-${version}.tar.gz"
		local extraimgopt_archive="${version_date}/pdfsizeopt_libexec_extraimgopt_linux-${version}.tar.gz"

		local pso_dir="/home/$SUDO_USER/src-bin/pdfsizeopt/"
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
		# TODO Look into docker version (not updated frequently, but maybe easier setup, isolated)
		# TODO Install pdftk and write a bash version of pdfcompress function
		# TODO Also see qpdf (haven't tried it yet)
		sudo -u "$SUDO_USER" -- mkdir -p "$pso_dir" && cd "$pso_dir" \
			&& curl -Lo pdfsizeopt.tar.gz "$download_base/$core_archive" \
			&& curl -Lo pdfsizeopt-extra.tar.gz "$download_base/$extraimgopt_archive" \
			&& tar xzvf pdfsizeopt.tar.gz && rm -f $_ \
			&& tar xzvf pdfsizeopt-extra.tar.gz && rm -f $_ \
			&& curl -Lo pdfsizeopt "$raw_base/pdfsizeopt.single" \
			&& chmod +x pdfsizeopt

		# TODO implement this:
		# 1. Create a file in the same directory named pdfsizeopt-all with the following content
		# #!/bin/bash
		#
		# ~/src-bin/pdfsizeopt/pdfsizeopt \
			#   --use-image-optimizer=sam2p,jbig2,pngout,zopflipng,optipng,advpng,ECT \
			#   "$@"
		#
		# 2. make it executable and available on the PATH
		# chmod +x pdfsizeopt-all
		# mkdir ~/bin/
		# ln -s $(pwd)/pdfsizeopt-all ~/bin/pdfsizeopt
	}
}


## sc-im ## {{{2

install_scim() {
	apt_install_custom+=(
		bison
		libncurses5-dev
		libncursesw5-dev
		libxml2-dev
		libzip-dev
		# We also need gcc, which is already installed via build-essential

		# Optional dependencies
		gnuplot-x11
			# gnuplot-doc
		xclip # Could instead be xsel, tmux, or other clipboard CLI tool
	)
	run_after_apt_install+=(__do_install_scim)

	__do_install_scim() {
		local parent_dir='src-bin'
		local repo_dir='sc-im'
		local repo_url='git@github.com:andmarti1424/sc-im.git'

		if ! [[ -d "/home/$SUDO_USER/$parent_dir/$repo_dir/src" ]]; then
			local vim_msg='TODO: Set default clipboard cmd to use xclip'
			local vim_cmd="echohl Title | echomsg '$vim_msg' | echohl None"

			su --login "$SUDO_USER" <<-EOF
				mkdir -p ~/$parent_dir/
				cd ~/"$parent_dir/"
				git clone "$repo_url" "$repo_dir"
				cd "$repo_dir/src"

				# Open the Makefile for the user to edit
				vim -c "$vim_cmd" ~/"$parent_dir/$repo_dir/src/Makefile" < /dev/tty

				make CC=gcc YACC='bison -y' SED=sed
				sudo make install
			EOF

			# TODO Make an alias or symlink named `scim` (easier than `sc-im`)
			# TODO Decide if I want to check out a tagged commit
			# - If it's v0.7.0, the executable is already called scim
			# TODO Create ~/.scimrc (or better, create it in the dotfiles repo)
		fi
	}
}


## webp ## {{{2

install_webp() {
	apt_install_custom+=(
		freeglut3-dev # OpenGL lib
		libgif-dev
		libjpeg-dev
		libpng-dev
		libtiff-dev
		mesa-common-dev # OpenGL lib
	)
	run_after_apt_install+=(__do_install_webp)

	__do_install_webp() {
		local webp_version_tag='v1.0.3' # TODO Update this as needed

		# TODO Make sure all these commands are actually run as SUDO_USER
		sudo -u "$SUDO_USER" -- mkdir dev && cd ~/dev
		sudo -u "$SUDO_USER" -- git clone https://chromium.googlesource.com/webm/libwebp \
			&& cd libwebp
		sudo -u "$SUDO_USER" -- git checkout -b "$webp_version_tag" "$webp_version_tag"
		sudo -u "$SUDO_USER" -- mkdir build && cd build
		sudo -u "$SUDO_USER" -- cmake ../
		sudo -u "$SUDO_USER" -- make

		# TODO Should I put this in the last command with && and sudo?
		make install
	}
}


## OBS ## {{{2

install_obs() {
	apt_ppa_repositories+=(ppa:obsproject/obs-studio)
	apt_install_custom+=(obs-studio)
}


# === OS Configuration === # {{{1


## Fix home directory permissions ## {{{2

home_dir_permissions() {
	run_before_apt_install+=(__do_home_dir_permissions)

	__do_home_dir_permissions() {
		# Set home directories to be readable only by their owners
		chmod 700 /home/*

		# Configure `adduser` to do the same for users created later
		local file='/etc/adduser.conf'

		if [[ -f "$file" ]]; then
			sed -i 's/^DIR_MODE=[0-7]*/DIR_MODE=0700/' "$file"
		fi
	}
}


## Disable hibernation ## {{{2

disable_hibernation() {
	run_before_apt_install+=(__do_disable_hibernation)

	__do_disable_hibernation() {
		local file='/etc/polkit-1/localauthority/50-local.d/com.ubuntu.enable-hibernate.pkla'

		# To undo this, just move the file back
		if [[ -f "$file" ]]; then
			mv "$file" /
		fi
	}
}


## Make terminal window opaque ## {{{2

terminal_window_background() {
	run_before_apt_install+=(__do_terminal_window_background)

	__do_terminal_window_background() {
		local file="/home/$SUDO_USER/.config/xfce4/terminal/terminalrc"

		if [[ -f "$file" ]]; then
			# If the config file has a "BackgroundMode" line, delete that line
			sed -i '/^BackgroundMode=/d' "$file"
		fi
	}
}


## Set ComposeKey to Menu key ## {{{2

compose_key() {
	run_before_apt_install+=(__do_compose_key)

	# Info on possible settings:
	# - `man keyboard`
	# - /usr/share/X11/xkb/rules/xorg.lst

	# All possible composed characters:
	# - /usr/share/X11/locale/en_US.UTF-8/Compose

	__do_compose_key() {
		local file='/etc/default/keyboard'

		if [[ -f "$file" ]]; then
			# NOTE: This change won't take effect until the next login
			sed -i 's/^XKBOPTIONS=.*$/XKBOPTIONS="compose:menu"/' "$file"
		fi
	}
}


## Increase the max number of files which can be watched ## {{{2

file_watcher_limits() {
	run_before_apt_install+=(__do_file_watcher_limits)

	# https://stackoverflow.com/a/24994331
	# https://github.com/guard/listen/wiki/Increasing-the-amount-of-inotify-watchers

	__do_file_watcher_limits() {
		# The default on my computer when writing this was 8192
		echo 'fs.inotify.max_user_watches=65536' >> /etc/sysctl.conf
		sysctl --system
	}
}


## Enable battery icon in system tray for laptops ## {{{2

# TODO Decide if I need to do this at all
battery_icon() {
	run_before_apt_install+=(__do_battery_icon)

	__do_battery_icon() {
		if (( $is_laptop )); then
			: # TODO implement this
		fi
	}
}


## Configure clock ## {{{2

configure_clock() {
	run_before_apt_install+=(__do_configure_clock)

	__do_configure_clock() {
		: # TODO
		# Might relate to this file: ~/.config/xfce4/panel/datetime-5.rc
	}
}


## Decrease swap use & improve RAM use on low-spec computers ## {{{2

adjust_memory_usage() {
	: # TODO Either implement this, delete it, or write it as manual instructions
	# (untested, but something like:)
	# (test for memory < 4 GB)
	# echo "# Decrease swap usage to a more reasonable level" >> /etc/sysctl.conf
	# echo "vm.swappiness=10" >> /etc/sysctl.conf
	# (test for memory > 1 GB)
	# echo "# Improve cache management" >> /etc/sysctl.conf
	# echo "vm.vfs_cache_pressure=50" >> /etc/sysctl.conf
	# Reboot the computer
	# Check: `cat /proc/sys/vm/swappiness` should output `10`
}


## Enable Uncomplicated Firewall ## {{{2

firewall_setup() {
	apt_install_minimum+=(ufw)
	run_after_apt_install+=(__do_firewall_setup)

	# Check firewall status: `sudo ufw status verbose`

	__do_firewall_setup() {
		# TODO Actually configure firewall
		ufw enable
	}
}


## Configure git ## {{{2

configure_git() {
	run_after_apt_install+=(__do_configure_git)

	__do_configure_git() {
		local name email
		read -p '(for git config) Enter full name: ' name
		read -p '(for git config) Enter email: ' email

		sudo -u "$SUDO_USER" -- git config --global user.name "$name"
		sudo -u "$SUDO_USER" -- git config --global user.email "$email"
		sudo -u "$SUDO_USER" -- git config --global core.editor 'vim'
		# TODO: Revisit diff.tool config - probably gvimdiff, gvimdiff2, or gvimdiff3
		sudo -u "$SUDO_USER" -- git config --global diff.tool 'gvimdiff3'
		# sudo -u "$SUDO_USER" -- git config --global core.excludesfile '~/.gitignore-global'
		# sudo -u "$SUDO_USER" -- touch "/home/$SUDO_USER/.gitignore-global"
		# sudo -u "$SUDO_USER" -- git config --global init.templatedir '~/.git-templates'
		sudo -u "$SUDO_USER" -- git config --global merge.conflictstyle 'diff3'
		sudo -u "$SUDO_USER" -- git config --global push.default 'nothing'

		# Disable the pager for common subcommands by default
		#
		# This addresses the issue where the paged output fails to clear from the
		# terminal on exit. The pager can be used manually by passing -p to git:
		#     $ git -p diff
		#
		# Another option if I *do* want the auto-paging, but only for long output:
		# https://unix.stackexchange.com/a/183676
		sudo -u "$SUDO_USER" -- git config --global pager.diff 'false'
		sudo -u "$SUDO_USER" -- git config --global pager.log 'false'
		sudo -u "$SUDO_USER" -- git config --global pager.status 'false'

		# Never exit the pager automatically, and reset the screen when it *is* exited
		sudo -u "$SUDO_USER" -- git config --global core.pager 'less -+F -+X'
	}
}


## Configure firejail ## {{{2

configure_firejail() {
	run_after_apt_install+=(__do_configure_firejail)

	__do_configure_firejail() {
		# Set up file(s) for custom firejail permissions
		# They will persist when updating firejail
		# TODO Run these in a subshell or replace "~" with "/home/$SUDO_USER"
		sudo -u "$SUDO_USER" -- mkdir ~/.config/firejail
		sudo -u "$SUDO_USER" -- cp /etc/firejail/firefox.profile ~/.config/firejail
		sudo -u "$SUDO_USER" -- cp /etc/firejail/chromium.profile ~/.config/firejail
		sudo -u "$SUDO_USER" -- cp /etc/firejail/chromium-browser.profile ~/.config/firejail

		# TODO Implement this, delete it, or print out a reminder to do it
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
	}
}




# === MAIN EXECUTION === # {{{1

main() {
	update_config

	# The functions in the following 2 blocks don't do their work immediately
	# Instead, they queue up work to be done in the loops below

	# Installation setup
	install_chrome
	install_codecs
	install_node_js
	install_golang
	install_aws_cli
	install_github_cli
	install_pdfsizeopt
	install_scim
	install_webp
	install_obs

	# Configuration setup
	home_dir_permissions
	disable_hibernation
	terminal_window_background
	compose_key
	file_watcher_limits
	#battery_icon
	#configure_clock
	#adjust_memory_usage
	firewall_setup
	configure_git
	#configure_firejail

	local function_name

	# Run pre-install functions
	for function_name in "${run_before_apt_install[@]}"; do
		"$function_name"
	done

	install_apt_packages
	install_snap_packages
	install_npm_packages
	install_pipx_packages

	# TODO Register this task in function instead of inside main()
	# This is needed so that libdvd-pkg can install updates from source
	# The execution of this command requires human interaction
	dpkg-reconfigure libdvd-pkg

	# Run post-install functions
	for function_name in "${run_after_apt_install[@]}"; do
		"$function_name"
	done
}

main "$@"

# vim: tabstop=2 shiftwidth=0 noexpandtab foldmethod=marker
