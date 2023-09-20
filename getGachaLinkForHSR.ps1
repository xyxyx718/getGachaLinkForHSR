# encoding: gbk

# �ݹ���� Star Rail �� config.ini �ļ��Ի�ȡ��Ϸ��װ·��
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

# ����Ŀ���ļ� data_2
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

Write-Host "���ű����ԣ�https://github.com/xyxyx718/getGachaLinkForHSR"
Write-Host "������΢��С���� ����ı������� ��ʹ����ȡ�������ӷ���ԾǨ��¼"

Write-Host "����ԾǨ��¼�С�"

# ���������̷�
$drives = Get-PSDrive -PSProvider 'FileSystem'
foreach ($drive in $drives) {
    $root = $drive.Root
    $gameInstallPath = Get-GameInstallPath -path $root -depth 0
    if ($gameInstallPath) {
        Write-Host "�ҵ���Ϸ��װ·����$gameInstallPath"
        $targetFile = Find-TargetFile -path $gameInstallPath
        if ($targetFile) {
            Write-Host "�ҵ�Ŀ���ļ���$targetFile`n"
    
            $fileContent = Get-Content $targetFile -Raw
            $pattern = 'https://api-takumi\.mihoyo\.com/common/gacha_record/api/getGachaLog\?(?=.*authkey=)(?=.*region=)(?=.*gacha_id=)(?=.*gacha_type=).*?(?=\{)'
            $foundMatches = [regex]::Matches($fileContent, $pattern)
    
            if ($foundMatches.Count -gt 0) {
                $latestMatch = $foundMatches[$foundMatches.Count - 1]
                Write-Host "���µ���Ч���ӣ�"
                Write-Host "$($latestMatch.Value)`n"
                Write-Host "�����ʹ����껮��ѡ�к󣬰��� Ctrl+C ��������������ӡ�"
    
                $fileInfo = Get-Item $targetFile
                $lastModifiedTime = $fileInfo.LastWriteTime.ToString("yyyy/MM/dd HH:mm:ss")
                Write-Host "data_2�ļ�����޸��� $lastModifiedTime ��ԾǨ��¼������Ч��һ�졣"
    
                $currentTimestamp = Get-Date
                $timeDifference = $currentTimestamp - $fileInfo.LastWriteTime
                if ($timeDifference.TotalHours -gt 23) {
                    Write-Host "���棺�����ӿ��ܹ��ڡ�������ڣ��������Ϸ���²鿴ԾǨ��¼��"
                }
            } else {
                Write-Host "δ�ҵ���Ч����"
            }
            break
        }
        else {
            Write-Host "δ�ҵ�Ŀ���ļ�"
            break
        }
    }
}

Read-Host "��������رմ���..."
