<#
.SYNOPSIS
    拉取 NexioSchedule 源码快照（走 codeload zip，避开 git clone 在受限网络的失败）。

.DESCRIPTION
    仅下载与解包，不改动目标目录以外的任何文件。目标目录已存在且非空时默认拒绝，
    需显式 -Force（会先移到 <Dest>.bak-<时间戳>，不直接删除）。

.EXAMPLE
    pwsh -File scripts\fetch-source.ps1 -Dest D:\work\NexioSchedule

.EXAMPLE
    pwsh -File scripts\fetch-source.ps1 -Dest D:\work\NexioSchedule -Commit 28a99a3b23458a0d39741b9841c9755f5374fba2 -Force
#>
param(
    [Parameter(Mandatory = $true)][string]$Dest,
    [string]$Branch = 'master',
    [string]$Commit,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$Repo = 'HaoZai000/NexioSchedule'
$ProgressPreference = 'SilentlyContinue'

if ($Commit) {
    $url = "https://codeload.github.com/$Repo/zip/$Commit"
    $tag = $Commit.Substring(0, [Math]::Min(8, $Commit.Length))
} else {
    $url = "https://codeload.github.com/$Repo/zip/refs/heads/$Branch"
    $tag = $Branch
}

$destFull = [IO.Path]::GetFullPath($Dest)
$zipPath = Join-Path ([IO.Path]::GetTempPath()) ("nexio-src-" + [Guid]::NewGuid().ToString('n') + ".zip")
$tmpDir = Join-Path ([IO.Path]::GetTempPath()) ("nexio-src-" + [Guid]::NewGuid().ToString('n'))

if (Test-Path -LiteralPath $destFull) {
    $existing = Get-ChildItem -LiteralPath $destFull -Force | Select-Object -First 1
    if ($existing -and -not $Force) {
        throw "目标目录非空：$destFull`n如需覆盖请加 -Force（会先备份为 .bak-<时间戳>，不会直接删除）。"
    }
}

Write-Host "下载 $url"
Invoke-WebRequest -Uri $url -OutFile $zipPath -UseBasicParsing -TimeoutSec 300
if (-not (Test-Path -LiteralPath $zipPath)) { throw '下载失败：文件不存在' }
Write-Host ("压缩包 " + [Math]::Round((Get-Item -LiteralPath $zipPath).Length / 1MB, 1) + " MB")

New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
Expand-Archive -LiteralPath $zipPath -DestinationPath $tmpDir -Force

$top = Get-ChildItem -LiteralPath $tmpDir -Directory | Select-Object -First 1
if (-not $top) { throw "解包结果异常：$tmpDir 下没有目录" }

if (Test-Path -LiteralPath $destFull) {
    $bak = "$destFull.bak-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
    # 目标存在时整体改名备份，绝不直接删除用户目录
    Move-Item -LiteralPath $destFull -Destination $bak
    Move-Item -LiteralPath $top.FullName -Destination $destFull
    Write-Host "旧目录已备份到 $bak"
} else {
    $parent = Split-Path -Parent $destFull
    if (-not (Test-Path -LiteralPath $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Move-Item -LiteralPath $top.FullName -Destination $destFull
}

Remove-Item -LiteralPath $zipPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tmpDir -Recurse -Force -ErrorAction SilentlyContinue

# 记录版本，供 references/source-map.md 对照
$head = git -C $destFull rev-parse HEAD 2>$null
if (-not $head) {
    $headFile = Join-Path $destFull '.git-commit'
    Set-Content -LiteralPath $headFile -Value $tag -Encoding utf8
    $head = $tag
}

$kt = (Get-ChildItem -LiteralPath $destFull -Recurse -Filter *.kt -File).Count
Write-Host "完成：$destFull（Kotlin 文件 $kt 个，版本 $head）"
Write-Host "下一步：python scripts\snapshot-tokens.py `"$destFull`""
#>
