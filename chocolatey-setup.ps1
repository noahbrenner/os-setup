# Before using this script, you will need to run:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned


# === Install chocolatey === #

Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression


# === Install packages === #

# TODO Use standalone/command line versions of packages
choco install 7zip.install
choco install anki
choco install audacity
choco install audacity-lame
choco install autohotkey.portable
choco install comicrack
choco install eac # Exact Audio Copy
choco install fsviewer # FastStone Image Viewer
choco install gnuwin32-make.portable
choco install nodejs # Or could choose nodejs-lts
choco install ffmpeg
choco install git.install -params '"/NoShellIntegration"'
choco install git-lfs.install
choco install mediamonkey
choco install poshgit # Check $profile after this install, it added unwanted lines
choco install pandoc --ia=ALLUSERS=1
# choco install vim # INSTEAD manually download from: http://www.vim.org/download.php#pc
