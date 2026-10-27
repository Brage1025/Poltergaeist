@echo off
rem Builds dist\Poltergaeist\Poltergaeist.exe (a folder build, not a single file:
rem it starts faster and triggers fewer antivirus false positives).
chcp 65001 >nul
setlocal
cd /d "%~dp0"

python -m pip install -r requirements.txt pyinstaller || goto :err
python make_icon.py || goto :err

python -m PyInstaller --noconfirm --clean --onedir --noconsole ^
  --name Poltergaeist --icon icon.ico ^
  --collect-all sounddevice ^
  --add-data "assets;assets" ^
  --hidden-import PIL.ImageTk ^
  --hidden-import pynput.keyboard._win32 ^
  --hidden-import pynput.mouse._win32 ^
  --hidden-import pystray._win32 ^
  haunt.py || goto :err

echo.
echo Built: dist\Poltergaeist\Poltergaeist.exe
echo To make an installer, open installer.iss in Inno Setup and press Compile.
goto :eof

:err
echo.
echo Build failed. If the folder path contains special characters, try building
echo from a plain path such as C:\poltergaeist
exit /b 1