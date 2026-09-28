# 一键做卡（Windows）：调用 WSL 里的 build-armbian-card.sh，生成 xxx-鸭子卡.img，拿 Rufus 烧。
# 用法：先改同目录 card.conf（WiFi 名/密码），右键此文件 -> 使用 PowerShell 运行，选 Armbian 的 .img.xz。
# 要装了 WSL2（管理员 PowerShell 跑 wsl --install，重启一次）。不用管理员权限。
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
if ((Get-Content (Join-Path $PSScriptRoot 'card.conf') -Raw) -match '改成你的') { Write-Host '先把 card.conf 里的 WiFi 名和密码改掉' -ForegroundColor Red; Read-Host '回车退出'; exit 1 }
$dlg = New-Object System.Windows.Forms.OpenFileDialog
$dlg.Filter = 'Armbian 镜像 (*.img.xz)|*.img.xz'; $dlg.Title = '选 Armbian_26.2.1_Radxa-zero3_trixie_vendor_6.1.115_minimal.img.xz'
if ($dlg.ShowDialog() -ne 'OK') { exit }
function ToWsl($p) { '/mnt/' + $p.Substring(0,1).ToLower() + $p.Substring(2).Replace('\','/') }
$distro = ((wsl -l -q) -replace "`0", '' | Where-Object { $_ -and $_ -notlike 'docker-desktop*' } | Select-Object -First 1)
if (-not $distro) { Write-Host 'WSL 里没有 Linux 发行版：管理员 PowerShell 里跑 wsl --install，重启再来' -ForegroundColor Red; Read-Host '回车退出'; exit 1 }
$env:WSL_UTF8 = 1
wsl -d $distro.Trim() -u root -- bash (ToWsl (Join-Path $PSScriptRoot 'build-armbian-card.sh')) (ToWsl $dlg.FileName) (ToWsl (Join-Path $PSScriptRoot 'card.conf'))
if ($LASTEXITCODE -eq 0) { Write-Host "`n成功。Rufus 里选生成的 -鸭子卡.img 烧卡。" -ForegroundColor Green } else { Write-Host "`n失败，把上面的输出贴群里问。" -ForegroundColor Red }
Read-Host '回车退出'
