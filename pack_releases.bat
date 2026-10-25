@echo off
setlocal
cd /d "%~dp0"

if not exist "releases" mkdir "releases"

echo ============================================================
echo   MoonRadio Aurora - Pembuat Paket ZIP untuk GitHub Releases
echo ============================================================
echo.

if not exist "dist\MoonRadio\moonloader\radio\bin\ffmpeg.exe" (
    echo [PERINGATAN] ffmpeg.exe belum ditemukan di:
    echo   dist\MoonRadio\moonloader\radio\bin\ffmpeg.exe
    echo   ^(Salin ffmpeg.exe terlebih dahulu jika ingin membuat paket full siap pakai^)
    echo.
)

if not exist "dist\MoonRadio_Win7\moonloader\radio\bin\ffmpeg.exe" (
    echo [PERINGATAN] ffmpeg.exe belum ditemukan di:
    echo   dist\MoonRadio_Win7\moonloader\radio\bin\ffmpeg.exe
    echo   ^(Salin ffmpeg.exe versi Win7 terlebih dahulu jika ingin membuat paket Win7 full^)
    echo.
)

echo [1/2] Membuat releases\MoonRadio_v4.0.0_Win10_11.zip ...
powershell -NoProfile -Command "Compress-Archive -Path 'dist\MoonRadio\*' -DestinationPath 'releases\MoonRadio_v4.0.0_Win10_11.zip' -Force"

echo [2/2] Membuat releases\MoonRadio_v4.0.0_Win7.zip ...
powershell -NoProfile -Command "Compress-Archive -Path 'dist\MoonRadio_Win7\*' -DestinationPath 'releases\MoonRadio_v4.0.0_Win7.zip' -Force"

echo.
echo ============================================================
echo   SELESAI! File siap diunggah ke GitHub Releases:
echo   - releases\MoonRadio_v4.0.0_Win10_11.zip
echo   - releases\MoonRadio_v4.0.0_Win7.zip
echo ============================================================
