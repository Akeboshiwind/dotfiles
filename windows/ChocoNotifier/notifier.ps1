$ErrorActionPreference = "Stop"
Write-Host "Importing BurntToast"
Import-Module -Name BurntToast

Write-Host "Loading outdated list"
$outdated = (choco outdated -r | Select-String '^([^|]+)|.*$').Matches | ForEach-Object {$_.Value}
$pretty = ($outdated -join ', ')

Write-Host "Doing check"
If ($outdated.count -gt 0) {
    Write-Host "Sending outdated notification"
    New-BurntToastNotification -Text "Outdated packages", "$pretty" -AppLogo $PSScriptRoot\choco-icon.png
} Else {
    Write-Host "Sending up to date notification"
    New-BurntToastNotification -Text "Up to date" -AppLogo $PSScriptRoot\choco-icon.png
}
