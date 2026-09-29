<# : Convertir a 1080p (Windows). Arrastra la carpeta de videos encima de este archivo.
@echo off
set "DROP=%~1"
set "HERE=%~dp0"
set "SELF=%~f0"
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ([IO.File]::ReadAllText($env:SELF))"
echo.
pause
exit /b
#>
$ErrorActionPreference = 'Continue'
$host.UI.RawUI.WindowTitle = 'Convertir a 1080p'
function Say($es, $en) { Write-Host "$es" -ForegroundColor Cyan; if ($en) { Write-Host "   $en" -ForegroundColor DarkGray } }

# 1. ffmpeg (se instala solo la primera vez)
$links = ''; if ($env:LOCALAPPDATA) { $links = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links' }
if ($links -and (Test-Path $links)) { $env:PATH = "$links;$env:PATH" }
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  Say 'Instalando ffmpeg (solo la primera vez, 1-2 minutos)...' 'Installing ffmpeg (first time only)...'
  winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements | Out-Host
  $env:PATH = [Environment]::GetEnvironmentVariable('PATH', 'Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH', 'User') + ";$links"
}
if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
  Say 'No se pudo instalar ffmpeg. Cierra esta ventana y vuelve a abrir el archivo.' 'Could not install ffmpeg. Close this window and open the file again.'
  return
}

# 2. Carpeta: la que arrastras encima, o la carpeta donde esta este archivo
$folder = $env:DROP
if (-not $folder -or -not (Test-Path -LiteralPath $folder -PathType Container)) { $folder = $env:HERE }
$folder = $folder.TrimEnd('\', '/')
$out = Join-Path $folder '1080p'
$exts = '.mp4', '.mov', '.m4v', '.mkv', '.avi', '.mts'
$vids = @(Get-ChildItem -LiteralPath $folder -File -Force | Where-Object {
  ($exts -contains $_.Extension.ToLower()) -and -not ($_.Name.StartsWith('._') -and $_.Length -lt 1MB)
} | Sort-Object Name)
Say "Carpeta: $folder" "Folder: $folder"
Say "$($vids.Count) video(s). Los de 1080p se guardan en: $out" "$($vids.Count) video(s). Output: $out"
Write-Host ''
if ($vids.Count -eq 0) { Say 'No hay videos aqui. Arrastra la CARPETA de videos encima del archivo.' 'No videos here. Drag the video FOLDER onto this file.'; return }
New-Item -ItemType Directory -Force -Path $out | Out-Null

function NewName($name) {
  $stem = [IO.Path]::GetFileNameWithoutExtension($name)
  if ($stem.StartsWith('._')) { $stem = $stem.Substring(2) }
  if ($stem -match '^(.*)_(3840|2160|4K|4k|3840px|2160px)$') { return $Matches[1] + '_1080p.mp4' }
  return $stem + '_1080p.mp4'
}

$done = 0; $skipped = 0; $failed = 0; $i = 0
foreach ($v in $vids) {
  $i++
  $dst = Join-Path $out (NewName $v.Name)
  Write-Host "[$i/$($vids.Count)] $($v.Name)" -NoNewline
  if (Test-Path -LiteralPath $dst) { Write-Host '  ya estaba hecho / already done' -ForegroundColor DarkGray; $skipped++; continue }
  $j = & ffprobe -v error -select_streams v:0 -show_entries 'stream=width,height:stream_tags=rotate:stream_side_data=rotation' -of json "$($v.FullName)" 2>$null | Out-String
  $w = 0; $h = 0
  try { $s = ($j | ConvertFrom-Json).streams[0]; $w = [int]$s.width; $h = [int]$s.height } catch {}
  if ($w -eq 0) { Write-Host '  no se puede leer / cannot read' -ForegroundColor Red; $failed++; continue }
  if ([Math]::Max($w, $h) -le 1920) { Write-Host "  ya es ${w}x${h}, se deja igual / already small" -ForegroundColor DarkGray; $skipped++; continue }
  Write-Host "  ${w}x${h} -> 1080p ..." -NoNewline
  $t = Get-Date
  $tmp = $dst + '.part.mp4'
  & ffmpeg -y -hide_banner -loglevel error -i "$($v.FullName)" -vf "scale='if(gt(iw,ih),1920,-2)':'if(gt(iw,ih),-2,1920)'" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "$tmp"
  if ($LASTEXITCODE -eq 0 -and (Test-Path -LiteralPath $tmp)) {
    Move-Item -LiteralPath $tmp -Destination $dst -Force
    Write-Host ("  OK ({0:N0}s)" -f ((Get-Date) - $t).TotalSeconds) -ForegroundColor Green; $done++
  } else {
    if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
    Write-Host '  ERROR' -ForegroundColor Red; $failed++
  }
}
Write-Host ''
Say "Listo: $done convertidos, $skipped saltados, $failed con error." "Done: $done converted, $skipped skipped, $failed failed."
Say 'Si cierras la ventana a medias, vuelve a abrirlo: sigue donde lo dejaste.' 'If you stop halfway, run it again: it continues where it left off.'
if ($env:OS -eq 'Windows_NT') { Start-Process explorer.exe -ArgumentList "`"$out`"" }
