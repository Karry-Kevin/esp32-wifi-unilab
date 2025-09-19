# 参数区
$owner    = "Karry-Kevin"
$repo     = "esp32-wifi-unilab"
$csvFile  = "m1.csv"

# 1. 创建 Milestone（如已存在会跳过）
$milestone = gh api repos/$owner/$repo/milestones --method POST --field title="M1-RepoSkeleton" --field state=open | ConvertFrom-Json
$msNumber  = $milestone.number

# 2. 逐行建 Issue 并加入 Project
Import-Csv $csvFile | ForEach-Object {
    $title = $_.title
    $body  = $_.body -replace "<CR>", "`n"   # 把<CR>换成换行
    $label = $_.labels
    gh issue create --title $title --body $body --label $label --milestone $msNumber --project $repo
}