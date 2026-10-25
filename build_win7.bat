@echo off
setlocal
cd /d "%~dp0"
echo === MoonRadio build (Windows 7 compatible) ===
rem Butuh Python 3.8 *32-bit* (versi terakhir yang mendukung Windows 7) HANYA di PC pembuat.
rem Unduh: https://www.python.org/ftp/python/3.8.10/python-3.8.10.exe
rem Atau set PY38 ke python.exe 3.8 32-bit, contoh:
rem   set PY38=C:\Users\Anda\Python38-32\python.exe

if "%PY38%"=="" (
    if exist "%USERPROFILE%\Python38-32\python.exe" set "PY38=%USERPROFILE%\Python38-32\python.exe"
)
if "%PY38%"=="" (
    where py >nul 2>nul && for /f "delims=" %%i in ('py -3.8-32 -c "import sys;print(sys.executable)" 2^>nul') do set PY38=%%i
)
if "%PY38%"=="" (
    echo Python 3.8 32-bit tidak ditemukan. Instal lalu set PY38=path\python.exe
    exit /b 1
)
echo Memakai: %PY38%

if not exist build\venv38 (
    "%PY38%" -m venv build\venv38 || exit /b 1
)
call build\venv38\Scripts\activate.bat
python -m pip install --upgrade pip >nul
python -m pip install -r requirements-build-win7.txt || exit /b 1
if exist "build\venv\Lib\site-packages\ytmusicapi" (
    python packaging\patch_ytmusicapi_py38.py "build\venv\Lib\site-packages\ytmusicapi" "build\venv38\Lib\site-packages\ytmusicapi" || exit /b 1
)

pyinstaller --noconfirm --clean --onefile --noconsole ^
    --name MoonRadioBridge ^
    --distpath build\out_win7 ^
    --workpath build\work_win7 ^
    --specpath build ^
    --paths src ^
    --collect-all ytmusicapi ^
    src\music_player.py || exit /b 1

echo === Menyusun paket Win7 ===
set PKG=dist\MoonRadio_Win7
mkdir "%PKG%\moonloader\radio\bin" 2>nul
copy /y src\MoonRadio_Aurora.lua "%PKG%\moonloader\MoonRadio_Aurora.lua" >nul
copy /y build\out_win7\MoonRadioBridge.exe "%PKG%\moonloader\radio\MoonRadioBridge.exe" >nul
copy /y README.md "%PKG%\README.md" >nul
copy /y "packaging\PUT_FFMPEG_HERE_WIN7.txt" "%PKG%\moonloader\radio\bin\PUT_FFMPEG_HERE.txt" >nul

echo.
echo Selesai: %CD%\%PKG%
echo Taruh ffmpeg.exe (versi 7.0.x essentials) ke %PKG%\moonloader\radio\bin\ lalu zip.
endlocal
exit /b 0
