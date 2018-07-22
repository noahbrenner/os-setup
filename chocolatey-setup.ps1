# Before using this script, you will need to run:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned

# install chocolatey
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

# install packages
# TODO use standalone/command line versions of packages
choco install 7zip.install
choco install anki
choco install audacity
choco install audacity-lame
choco install autohotkey.portable
choco install comicrack
choco install eac # Exact Audio Copy
choco install fsviewer # FastStone Image Viewer
choco install gnuwin32-make.portable
choco install nodejs # or could choose nodejs-lts
choco install ffmpeg
choco install git.install -params '"/NoShellIntegration"'
choco install git-lfs.install
choco install mediamonkey
choco install poshgit # check $profile after this install, it added unwanted lines
choco install pandoc --ia=ALLUSERS=1
# choco install vim # INSTEAD manually download from: http://www.vim.org/download.php#pc
