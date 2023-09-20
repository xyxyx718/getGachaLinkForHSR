# encoding: gbk

# 递归查找 Star Rail 的 config.ini 文件以获取游戏安装路径
Function Get-GameInstallPath {
    param (
        [string]$path,
        [int]$depth
    )
    
    if ($depth -gt 2) {
        return $null
    }
    
    $configPath = Join-Path $path 'Star Rail\config.ini'
    if (Test-Path $configPath) {
        $configContent = Get-Content $configPath
        $inLauncherSection = $false
        foreach ($line in $configContent) {
            if ($line -eq '[launcher]') {
                $inLauncherSection = $true
            }
            elseif ($inLauncherSection -and $line -match '^game_install_path=(.*)$') {
                return $matches[1]
            }
        }
    }
    
    $subfolders = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $subfolders) {
        $installPath = Get-GameInstallPath -path $folder.FullName -depth ($depth + 1)
        if ($installPath) {
            return $installPath
        }
    }
    return $null
}

# 查找目标文件 data_2
Function Find-TargetFile {
    param (
        [string]$path
    )
    $targetPath = Join-Path $path 'StarRail_Data\webCaches'
    if (Test-Path $targetPath) {
        $versions = Get-ChildItem -Path $targetPath -Directory
        $highestVersion = $versions | Sort-Object { $_.Name } -Descending | Select-Object -First 1
        $targetFile = Join-Path $highestVersion.FullName 'Cache\Cache_Data\data_2'
        if (Test-Path $targetFile) {
            return $targetFile
        }
    }
    return $null
}

Write-Host "本脚本来自：https://github.com/xyxyx718/getGachaLinkForHSR"
Write-Host "可以在微信小程序 咸鱼的崩铁助理 中使用提取到的链接分析跃迁记录"

Write-Host "查找跃迁记录中…"

# 遍历所有盘符
$drives = Get-PSDrive -PSProvider 'FileSystem'
foreach ($drive in $drives) {
    $root = $drive.Root
    $gameInstallPath = Get-GameInstallPath -path $root -depth 0
    if ($gameInstallPath) {
        Write-Host "找到游戏安装路径：$gameInstallPath"
        $targetFile = Find-TargetFile -path $gameInstallPath
        if ($targetFile) {
            Write-Host "找到目标文件：$targetFile`n"
    
            $fileContent = Get-Content $targetFile -Raw
            $pattern = 'https://api-takumi\.mihoyo\.com/common/gacha_record/api/getGachaLog\?(?=.*authkey=)(?=.*region=)(?=.*gacha_id=)(?=.*gacha_type=).*?(?=\{)'
            $foundMatches = [regex]::Matches($fileContent, $pattern)
    
            if ($foundMatches.Count -gt 0) {
                $latestMatch = $foundMatches[$foundMatches.Count - 1]
                Write-Host "最新的有效链接："
                Write-Host "$($latestMatch.Value)`n"
                Write-Host "你可以使用鼠标划动选中后，按下 Ctrl+C 来复制上面的链接。"
    
                $fileInfo = Get-Item $targetFile
                $lastModifiedTime = $fileInfo.LastWriteTime.ToString("yyyy/MM/dd HH:mm:ss")
                Write-Host "data_2文件最后修改于 $lastModifiedTime ，跃迁记录链接有效期一天。"
    
                $currentTimestamp = Get-Date
                $timeDifference = $currentTimestamp - $fileInfo.LastWriteTime
                if ($timeDifference.TotalHours -gt 23) {
                    Write-Host "警告：该链接可能过期。如果过期，请进入游戏重新查看跃迁记录。"
                }
            } else {
                Write-Host "未找到有效链接"
            }
            break
        }
        else {
            Write-Host "未找到目标文件"
            break
        }
    }
}

Read-Host "按任意键关闭窗口..."
