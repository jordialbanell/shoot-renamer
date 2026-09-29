@echo off
setlocal EnableExtensions DisableDelayedExpansion
title Convertir a 1080p
rem Arrastra la CARPETA de videos encima de este archivo.
rem Guarda copias en 1080p en una subcarpeta "1080p". Los originales no se tocan.

set "FOLDER=%~1"
if "%FOLDER%"=="" set "FOLDER=%~dp0"
if "%FOLDER:~-1%"=="\" set "FOLDER=%FOLDER:~0,-1%"
if not exist "%FOLDER%\" (
  echo Arrastra la CARPETA de videos encima de este archivo.
  pause
  exit /b
)

set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
where ffmpeg >nul 2>nul && goto :haveff
echo Instalando ffmpeg, solo la primera vez (1-2 minutos)...
winget install -e --id Gyan.FFmpeg --accept-source-agreements --accept-package-agreements
where ffmpeg >nul 2>nul && goto :haveff
echo.
echo No se pudo instalar ffmpeg. Cierra esta ventana y vuelve a arrastrar la carpeta.
pause
exit /b

:haveff
set "OUT=%FOLDER%\1080p"
if not exist "%OUT%\" mkdir "%OUT%"
set /a N=0, DONE=0, SKIP=0, FAIL=0
echo.
echo Carpeta: %FOLDER%
echo Los videos en 1080p se guardan en: %OUT%
echo.
for %%F in ("%FOLDER%\*.mov" "%FOLDER%\*.mp4" "%FOLDER%\*.m4v" "%FOLDER%\*.mts" "%FOLDER%\*.mkv") do call :one "%%~fF" %%~zF
echo.
echo Listo: %DONE% convertidos, %SKIP% saltados, %FAIL% con error.
echo Si lo cierras a medias, vuelve a arrastrar la carpeta: sigue donde lo dejo.
start "" explorer "%OUT%"
pause
exit /b

:one
set "SRC=%~1"
set "NAME=%~n1"
set "SIZE=%~2"
if "%NAME:~0,2%"=="._" if %SIZE% LSS 1000000 goto :eof
if "%NAME:~0,2%"=="._" set "NAME=%NAME:~2%"
set "BASE=%NAME%"
set "BASE=%BASE:_3840px=%"
set "BASE=%BASE:_2160px=%"
set "BASE=%BASE:_3840=%"
set "BASE=%BASE:_2160=%"
set "BASE=%BASE:_4K=%"
set "DST=%OUT%\%BASE%_1080p.mp4"
set "PART=%OUT%\%BASE%_1080p.part.mp4"
set /a N+=1
if exist "%DST%" (
  echo [%N%] "%BASE%" ya estaba hecho
  set /a SKIP+=1
  goto :eof
)
set "W="
set "H="
for /f "usebackq tokens=1,2 delims=," %%a in (`ffprobe -v error -select_streams v:0 -show_entries stream^=width^,height -of csv^=p^=0 "%SRC%"`) do (
  set "W=%%a"
  set "H=%%b"
)
if "%W%"=="" (
  echo [%N%] "%NAME%" no se puede leer
  set /a FAIL+=1
  goto :eof
)
set /a LONG=W
if %H% GTR %W% set /a LONG=H
if %LONG% LEQ 1920 (
  echo [%N%] "%NAME%" ya es %W%x%H%, se deja igual
  set /a SKIP+=1
  goto :eof
)
echo [%N%] "%NAME%" %W%x%H% - convirtiendo a 1080p...
ffmpeg -y -hide_banner -loglevel error -stats -i "%SRC%" -vf "scale='if(gt(iw,ih),1920,-2)':'if(gt(iw,ih),-2,1920)'" -c:v libx264 -preset fast -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k -movflags +faststart "%PART%"
if errorlevel 1 (
  if exist "%PART%" del "%PART%"
  echo      ERROR
  set /a FAIL+=1
  goto :eof
)
move /y "%PART%" "%DST%" >nul
echo      OK: %BASE%_1080p.mp4
set /a DONE+=1
goto :eof
