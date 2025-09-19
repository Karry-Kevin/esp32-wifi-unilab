# ===== 最简单版：只批量建 Issue =====
Clear-Host
Write-Host "========= 批量建 GitHub Issue（极简版） =========" -ForegroundColor Cyan

# $owner      = Read-Host "GitHub 用户名 (owner)"
# $repo       = Read-Host "仓库名 (repo)"
# $csvFile    = Read-Host "CSV 文件名 (含扩展名，例如 m1.csv)"
# $msNumber   = Read-Host "Milestone 数字 ID（网页上抄的那个，例如 5）"
# $projID     = Read-Host "Project 数字 ID（不想自动进看板直接回车）"

$owner    = "Karry-Kevin"
$repo     = "esp32-wifi-unilab"
$csvFile  = "m1.csv"
$msNumber   = "1"
$projID     = "3"


if (!(Test-Path $csvFile)) {
    Write-Host "找不到 $csvFile，脚本退出" -ForegroundColor Red
    Read-Host "按回车退出"
    exit
}

Import-Csv $csvFile | ForEach-Object {
    $title = $_.title
    $body  = $_.body -replace '<CR>', "`n"
    $label = $_.labels
    Write-Host "`n即将创建 Issue：$title"
    Read-Host "按回车继续（Ctrl+C 退出）"

    # 根据有没有 project ID 决定参数
    if ($projID) {
        gh issue create -R $owner/$repo --title $title --body $body --label $label --milestone $msNumber --project $projID
    } else {
        gh issue create -R $owner/$repo --title $title --body $body --label $label --milestone $msNumber
    }
    Write-Host "✅ 完成一条"
}

Write-Host "`n========= 全部执行完毕 =========" -ForegroundColor Cyan
Read-Host "按回车退出"