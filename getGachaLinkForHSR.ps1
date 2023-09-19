# encoding: gbk

# �������ڵݹ����Ŀ���ļ��ĺ���
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

# ���������̷�
$drives = Get-PSDrive -PSProvider 'FileSystem'

Write-Host "���ű����ԣ�https://github.com/xyxyx718/getGachaLinkForHSR"
Write-Host "������΢��С���� ����ı������� ��ʹ����ȡ�������ӷ���ԾǨ��¼"

Write-Host "����ԾǨ��¼�С�"

foreach ($drive in $drives) {
    $root = $drive.Root
    $targetFile = Find-TargetFile -path $root -depth 0

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

        Read-Host "��������رմ���..."
        exit
    }
}

Write-Host "δ�ҵ�Ŀ���ļ�"
Read-Host "��������رմ���..."
