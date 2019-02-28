#Requires -RunAsAdministrator
# ^ Check we have correct permissions
# Check powershell version
if ($PSVersionTable.PSVersion.Major -lt 3) {
    Write-Host "Powershell major version must be 3 or greater"
    exit
}
# Set HOME environment variable
## TODO: Ake user where they want home to be?
$HOMEDRIVE = "E:\"
$HOMEPATH = "ake"
[System.Environment]::SetEnvironmentVariable('HOME', "$HOMEDRIVE$HOMEPATH", [System.EnvironmentVariableTarget]::User)
Set-Variable -Name "HOME" -Value "$HOMEDRIVE$HOMEPATH" -Force

# Chocolatey
## Install
Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
## Setup Notifier
### Install files
New-Item -ItemType Directory -Path $HOME\Documents\WindowsPowerShell\Scripts\ChocoNotifier
New-Item -ItemType SymbolicLink -Path $HOME\Documents\WindowsPowerShell\Scripts\ChocoNotifier -Name notifier.ps1 -Target $HOME\ChocoNotifier\notifier.ps1
New-Item -ItemType SymbolicLink -Path $HOME\Documents\WindowsPowerShell\Scripts\ChocoNotifier -Name choco-icon.png -Target $HOME\ChocoNotifier\choco-icon.png
### Schedule Task
$action = New-ScheduledTaskAction -Execute 'Powershell.exe' `
  -Argument "-NoProfile -WindowStyle Hidden -ExecutionPolicy Bypass  -File $HOME\Documents\WindowsPowerShell\Scripts\ChocoNotifier\notifier.ps1"

$triggers = @()
$triggers += New-ScheduledTaskTrigger -Daily -At 00:17
$triggers += New-ScheduledTaskTrigger -AtLogon

Register-ScheduledTask -Action $action -Trigger $triggers -TaskName "ChocoNotifier" -Description "Check chocolatey for updates and if so display a notification."

# Keybinds
## Caps Lock -> Ctrl
$hexified = "00,00,00,00,00,00,00,00,02,00,00,00,1d,00,3a,00,00,00,00,00".Split(',') | % { "0x$_" };
$kbLayout = 'HKLM:\System\CurrentControlSet\Control\Keyboard Layout';
New-ItemProperty -Path $kbLayout -Name "Scancode Map" -PropertyType Binary -Value ([byte[]]$hexified);

# Install packages
## Git
choco install git.install -fy
### Link .gitconfig
#### TODO: Change references to home path, should be relative to where script is being run from.
New-Item -ItemType SymbolicLink -Path $HOME -Name .gitconfig -Target $HOME\.config\linux\.gitconfig

## Emacs
choco install emacs -fy
### Fonts
choco install hackfont -fy
choco install font-awesome-font -fy
### LaTeX
choco install msys2 -fy
choco install miktex.install -fy
#### pdf->png conversion for resume
choco install imagemagick.app -fy
choco install ghostscript.app -fy
### Spacemacs
#### Remove potential .emacs and .emacs.d/ files and folders
Remove-Item -path $HOME\.emacs.d\
Remove-Item -path $HOME\.emacs
#### Clone spacemacs
git clone -b develop https://github.com/syl20bnr/spacemacs $HOME\.emacs.d
#### Link .spacemacs
New-Item -ItemType SymbolicLink -Path $HOME -Name .spacemacs -Target $HOME\.config\linux\.spacemacs


## Google Chrome
choco install googlechrome -fy
### Set chrome as default browser
$chromePath = "${Env:ProgramFiles(x86)}\Google\Chrome\Application\"
$chromeApp = "chrome.exe"
$chromeCommandArgs = @('--make-default-browser')
Invoke-Expression “cmd.exe /C `"$chromePath$chromeApp`" $chromeCommandArgs”

## Others
choco install 7zip.install -fy
choco install ag -fy
choco install aquasnap -fy
choco install arq -fy
choco install audacity -fy
choco install discord.install -fy
choco install dropbox -fy
choco install filezilla -fy
choco install geforce-game-ready-driver -fy
choco install jre8 -fy
choco install keeweb -fy
choco install mumble -fy
choco install paint.net -fy
choco install plexmediaplayer -fy
choco install putty.install -fy
choco install sharex -fy
choco install shutup10 -fy
choco install spotify -fy
choco install steam -fy
choco install telegram.install -fy
choco install transmission -fy
choco install vlc -fy
choco install wiztree -fy
