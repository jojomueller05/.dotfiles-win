function Download-WinGet($downloadPath) {
    Write-Host "Installing Winget"
    # Installiere Winget:
    $githubRepo = "microsoft/winget-cli"
    $latestRelease = Invoke-RestMethod -Uri "https://api.github.com/repos/$githubRepo/releases/latest"

    # Erhalte das MSIX-Paket
    $msiData = $latestRelease.assets | Where-Object { $_.name -like "*.msixbundle" }

    $downloadFolder = Split-Path -Path $downloadPath -Parent
    $downloadFileName = Split-Path -Path $downloadPath -Leaf

    # Starte den Download und verfolge den Fortschritt
    $downloadJob = Start-BitsTransfer -Source $msiData.browser_download_url -Destination $downloadPath -Asynchronous

    do {
        $downloadProgress = Get-BitsTransfer -JobId $downloadJob.JobId
        $bytesTransferred = $downloadProgress.BytesTransferred
        $bytesTotal = $downloadProgress.BytesTotal
        $percentComplete = ($bytesTransferred / $bytesTotal) * 100

        $percentComplete = [math]::Round($percentComplete, 2)
        
        Write-Host "Downloading $percentComplete%" -NoNewline
        Start-Sleep -Seconds 1
        Write-Host (" " * 50) -NoNewline  # Löscht die vorherige Prozentsatzanzeige
        Write-Host ("`r" * 2)  # Positioniert den Cursor am Anfang der Zeile
    } While ($downloadProgress.JobState -ne "Transferred")

    Start-Sleep -Seconds 1
    $tempFile = Get-ChildItem -hidden $downloadFolder | Where-Object { $_.Name -like "BIT*.tmp" } | Select-Object Name

    if ($tempFile) {
        $tempFilePath = $downloadFolder + "\" + $tempFile.Name
        Rename-Item -Path $tempFilePath -NewName $downloadFileName
        Set-ItemProperty -Path $downloadPath -Name Attributes -Value Normal
        Write-Host "Download Complete." -ForegroundColor Green
        return $true  # Erfolgreich
    } else {
        Write-Host "Download fehlgeschlagen." -ForegroundColor Red
        return $false  # Fehlgeschlagen
    }
}

function Test-CommandExists($command){
    $oldPereference = $ErrorActionPreference
    $ErrorActionPreference = 'stop'
    try{
        if (Get-Command $command){
            return $true
        }
    }catch{
        return $false
    } finally {
        $ErrorActionPreference = $oldPereference
    }
}

function Install-Winget(){
    $tempPaht = ".\.temp"
    $wingetInstaller = ".\.temp\winget-latest.msixbundle"
    $pathExists = Test-Path $tempPaht

    if ($pathExists -eq $false){
        New-Item -Path $tempPaht -ItemType Directory
    }

    $installWinget = Download-WinGet($wingetInstaller)

    if ($installWinget -eq $true){
        $testWinget = Test-CommandExists winget

        Add-AppPackage -path $wingetInstaller

        if ($testWinget -eq $true){
            Remove-Item -Path $tempPaht
            return $true
        } else {
            return $false 
        }
    } 
}

function Check-InstallWSL2 {
    # Überprüfe, ob WSL 2 bereits installiert ist
    $wslVersionOutput = wsl --set-default-version 2 2>&1
    if ($wslVersionOutput -like "WSL 2 distros have been updated" -or $wslVersionOutput -like "The requested operation could not be completed due to a virtual disk system limitation.") {
        Write-Host "WSL 2 ist bereits installiert."
        return $true
    }

    # Installiere WSL 2
    Write-Host "WSL 2 wird installiert..."
    wsl --install

    # Überprüfe erneut, ob WSL 2 installiert ist
    $wslVersionOutput = wsl --set-default-version 2 2>&1
    if ($wslVersionOutput -like "WSL 2 distros have been updated") {
        Write-Host "WSL 2 wurde erfolgreich installiert."
        return $true
    } else {
        Write-Host "Fehler: WSL 2 konnte nicht installiert werden."
        return $false
    }
}