Function _g {
    param ($_p, $_d)
    if ($_d -gt 2) { return $null }
    $_cp = Join-Path $_p 'Star Rail\config.ini'
    if (Test-Path $_cp) {
        $_cc = Get-Content $_cp
        $_i = $false
        foreach ($_l in $_cc) {
            if ($_l -eq '[launcher]') { $_i = $true }
            elseif ($_i -and $_l -match '^game_install_path=(.*)$') { return $matches[1] }
        }
    }
    $_sf = Get-ChildItem -Path $_p -Directory -ErrorAction SilentlyContinue
    foreach ($_f in $_sf) {
        $_ip = _g -_p $_f.FullName -_d ($_d + 1)
        if ($_ip) { return $_ip }
    }
    return $null
}
Function Find-TargetFile {
    param ($_p)
    $_tp = Join-Path $_p 'StarRail_Data\webCaches'
    if (Test-Path $_tp) {
        $_v = Get-ChildItem -Path $_tp -Directory
        $_hv = $_v | Sort-Object { $_.Name } -Descending | Select-Object -First 1
        $_tf = Join-Path $_hv.FullName 'Cache\Cache_Data\data_2'
        if (Test-Path $_tf) { return $_tf }
    }
    return $null
}
Write-Host "本脚本来自：https://github.com/xyxyx718/getGachaLinkForHSR`n可以在微信小程序 咸鱼的崩铁助理 中使用提取到的链接分析跃迁记录`n查找跃迁记录中…"
$_ds = Get-PSDrive -PSProvider 'FileSystem'
foreach ($_d in $_ds) {
    $_r = $_d.Root
    $_gip = _g -_p $_r -_d 0
    if ($_gip) {
        Write-Host "找到游戏安装路径：$_gip"
        $_tf = Find-TargetFile -_p $_gip
        if ($_tf) {
            Write-Host "找到目标文件：$_tf`n"    
            $_fc = Get-Content $_tf -Raw
            $_pp = 'https://api-takumi\.mihoyo\.com/common/gacha_record/api/getGachaLog\?(?=.*authkey=)(?=.*region=)(?=.*gacha_id=)(?=.*gacha_type=).*?(?=\{)'
            $_fm = [regex]::Matches($_fc, $_pp)    
            if ($_fm.Count -gt 0) {
                $_lm = $_fm[$_fm.Count - 1]
                Write-Host "最新的有效链接：`n$($_lm.Value)`n`n你可以使用鼠标划动选中后，按下 Ctrl+C 来复制上面的链接。"    
                $_fi = Get-Item $_tf
                $_lt = $_fi.LastWriteTime.ToString("yyyy/MM/dd HH:mm:ss")
                Write-Host "data_2文件最后修改于 $_lt ，跃迁记录链接有效期一天。"
                $_ct = Get-Date
                $_dt = $_ct - $_fi.LastWriteTime
                if ($_dt.TotalHours -gt 23) { Write-Host "警告：该链接可能过期。如果过期，请进入游戏重新查看跃迁记录。" }
            }
            else { Write-Host "未找到有效链接" }
            break
        }
        else {
            Write-Host "未找到目标文件"
            break
        }
    }
}
Read-Host "按任意键关闭窗口..."