@echo off
setlocal
cd /d "%~dp0"
echo === MoonRadio build ===

where python >nul 2>nul || (echo Python tidak ditemukan. Instal Python 3.9+ khusus untuk BUILD ^(pemain tidak perlu^).& exit /b 1)

if not exist build\venv (
    python -m venv build\venv || exit /b 1
)
call build\venv\Scripts\activate.bat
python -m pip install --upgrade pip >nul
python -m pip install -r requirements-build.txt || exit /b 1

if exist dist rmdir /s /q dist
pyinstaller --noconfirm --clean --onefile --noconsole ^
    --name MoonRadioBridge ^
    --distpath build\out ^
    --workpath build\work ^
    --specpath build ^
    --paths src ^
    --collect-all ytmusicapi ^
    src\music_player.py || exit /b 1

echo === Menyusun paket ===
set PKG=dist\MoonRadio
mkdir "%PKG%\moonloader\radio\bin" 2>nul
copy /y src\MoonRadio_Aurora.lua "%PKG%\moonloader\MoonRadio_Aurora.lua" >nul
copy /y build\out\MoonRadioBridge.exe "%PKG%\moonloader\radio\MoonRadioBridge.exe" >nul
copy /y README.md "%PKG%\README.md" >nul
copy /y "packaging\PUT_FFMPEG_HERE.txt" "%PKG%\moonloader\radio\bin\PUT_FFMPEG_HERE.txt" >nul

echo.
echo Selesai: %CD%\%PKG%
echo Taruh ffmpeg.exe ke %PKG%\moonloader\radio\bin\ lalu zip folder MoonRadio.
endlocal
exit /b 0
