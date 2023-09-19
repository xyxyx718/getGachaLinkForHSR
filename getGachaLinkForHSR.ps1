# encoding: gbk

# 定义用于递归查找目标文件的函数
Function Find-TargetFile {
    param (
        [string]$path,
        [int]$depth
    )

    if ($depth -gt 1) {
        return $null
    }

    $starRailPath = Join-Path $path 'Star Rail\Games\StarRail_Data\webCaches'
    if (Test-Path $starRailPath) {
        $versions = Get-ChildItem -Path $starRailPath -Directory
        $highestVersion = $versions | Sort-Object { $_.Name } -Descending | Select-Object -First 1
        $targetFile = Join-Path $highestVersion.FullName 'Cache\Cache_Data\data_2'
        
        if (Test-Path $targetFile) {
            return $targetFile
        }
    }

    $subfolders = Get-ChildItem -Path $path -Directory -ErrorAction SilentlyContinue
    foreach ($folder in $subfolders) {
        $foundFile = Find-TargetFile -path $folder.FullName -depth ($depth + 1)
        if ($foundFile) {
            return $foundFile
        }
    }
    return $null
}

# 遍历所有盘符
$drives = Get-PSDrive -PSProvider 'FileSystem'

Write-Host "本脚本来自：https://github.com/xyxyx718/getGachaLinkForHSR"
Write-Host "可以在微信小程序 咸鱼的崩铁助理 中使用提取到的链接分析跃迁记录"

Write-Host "查找跃迁记录中…"

foreach ($drive in $drives) {
    $root = $drive.Root
    $targetFile = Find-TargetFile -path $root -depth 0

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

        Read-Host "按任意键关闭窗口..."
        exit
    }
}

Write-Host "未找到目标文件"
Read-Host "按任意键关闭窗口..."
