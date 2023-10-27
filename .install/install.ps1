. ".\functions.ps1"


$installWinget = Install-WinGet

if ($installWinget -eq $true){
    winget import -i ".\winget-export.json" --accept-package-agreements
} else {
    Write-Host "Couldn't Install Winget and Apps!"
}


