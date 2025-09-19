$owner = "Karry-Kevin"
$repo  = "esp32-wifi-unilab"
$labels = @{
    "infra"="0052CC"; "sta"="0E8A16"; "reliability"="FBCA04"; "provisioning"="5319E7"
    "ap"="D93F0B"; "dns"="0075ca"; "low-power"="27C6D9"; "ota"="FF9500"
    "security"="B60205"; "tls"="0052CC"; "mqtt"="0E8A16"; "sniffer"="FF48A4"
    "nat"="FFA500"; "mesh"="5319E7"; "http"="207DE5"; "websocket"="27C6D9"
    "ci"="1D76DB"; "qa"="FBCA04"; "doc"="0075ca"
}
# 先列出已有，避免 422
$exist = (gh api repos/$owner/$repo/labels --paginate | ConvertFrom-Json).name
$labels.GetEnumerator() | ForEach-Object {
    if ($_.Key -in $exist) {
        Write-Host "跳过已存在标签 $($_.Key)" -ForegroundColor DarkGray
    } else {
        Write-Host "创建标签 $($_.Key) 颜色 $($_.Value)" -ForegroundColor Green
        gh api repos/$owner/$repo/labels --method POST --raw-field name=$($_.Key) --raw-field color=$($_.Value)
    }
}
Write-Host "======== 全部标签创建完成 ========" -ForegroundColor Cyan