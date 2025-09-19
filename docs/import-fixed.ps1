# ESP32-UniLab-GitHub-批量建卡-可用版
Clear-Host
Write-Host "========= ESP32 UniLab GitHub 批量建卡（调试版） =========" -ForegroundColor Cyan

# $owner   = Read-Host "GitHub 用户名 (owner)"
# $repo    = Read-Host "仓库名 (repo)"
# $csvFile = Read-Host "CSV 文件名 (含扩展名，例如 m1.csv)"

# Write-Host "$owner"
# Write-Host "$repo"
# Write-Host "$csvFile"

$owner    = "Karry-Kevin"
$repo     = "esp32-wifi-unilab"
$csvFile  = "m1.csv"

Write-Host "`n【Step 0】检查 gh 是否可用" -ForegroundColor Yellow
gh auth status
if ($LASTEXITCODE -ne 0) {
    Write-Host "gh 没登录！请先运行 gh auth login" -ForegroundColor Red
    Read-Host "按回车退出"
    exit
}

# Write-Host "`n【Step 1】获取 Milestone 编号" -ForegroundColor Yellow
# $list = gh api repos/$owner/$repo/milestones --field state=open | ConvertFrom-Json

# Write-Host "gh api repos/$owner/$repo/milestones"

# $msNumber = ($list | Where-Object { $_.title -eq "M1-RepoSkeleton" }).number
# Write-Host "$msNumber"


# if (-not $msNumber) {
#     # 用 --raw-field 避免 422
#     $ms = gh api repos/$owner/$repo/milestones --method POST --raw-field title="M1-RepoSkeleton" --raw-field state=open | ConvertFrom-Json
#     $msNumber = $ms.number
# }
# Write-Host "使用 milestone number = $msNumber" -ForegroundColor Green

# # 2. 获取 Project 数字 ID（方案 B）
# Write-Host "`n【Step 2】获取 Project 数字 ID" -ForegroundColor Yellow
# $projID = (gh project list --owner $owner --limit 20 --json number,title | ConvertFrom-Json |
#            Where-Object { $_.title -eq "esp32-wifi-unilab" }).number
# if (-not $projID) {
#     Write-Host "找不到 Project ""esp32-wifi-unilab""，脚本继续，但卡片不会自动进看板" -ForegroundColor Yellow
#     $projID = $null          # 后面用 if 判断
# }
$msNumber = "1"
$projID = "3"
if (!(Test-Path $csvFile)) {
    Write-Host "找不到 $csvFile，脚本退出" -ForegroundColor Red
    Read-Host "按回车退出"
    exit
}

Import-Csv $csvFile | ForEach-Object {
    $title = $_.title
    $body  = $_.body -replace '<CR>', "`n"
    $label = $_.labels
    Write-Host "`n----------------------------------------" -ForegroundColor DarkGray
    Write-Host "即将创建 Issue：" -ForegroundColor Cyan
    Write-Host "  title : $title"
    Write-Host "  label : $label"
    Write-Host "  body  : $($body.Substring(0,[Math]::Min(60,$body.Length)))..."
    Read-Host "按回车继续"

    # 根据有无 projID 决定参数
    if ($projID) {
        $createJson = gh issue create --title $title --body $body --label $label --milestone $msNumber --project $projID
    } else {
        $createJson = gh issue create --title $title --body $body --label $label --milestone $msNumber
    }
    Write-Host "创建结果：$createJson" -ForegroundColor Gray
    Write-Host "✅ 创建成功" -ForegroundColor Green
}

Write-Host "`n========= 全部执行完毕 =========" -ForegroundColor Cyan
Read-Host "按回车退出"