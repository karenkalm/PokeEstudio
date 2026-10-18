@echo off
chcp 65001 >nul
title PokeStudio - servidor de desarrollo
cd /d "%~dp0"

rem Busca Flutter en el PATH; si no esta, en Descargas\flutter\flutter.
rem (Se usan rutas completas: llamar a "dart" por el PATH confunde a dart.bat.)
set "FLUTTER_BIN="
for /f "delims=" %%F in ('where flutter.bat 2^>nul') do if not defined FLUTTER_BIN set "FLUTTER_BIN=%%~dpF"
if not defined FLUTTER_BIN set "FLUTTER_BIN=%USERPROFILE%\Downloads\flutter\flutter\bin\"
set "POKESTUDIO_FLUTTER=%FLUTTER_BIN%flutter.bat"
set "DART_EXE=%FLUTTER_BIN%cache\dart-sdk\bin\dart.exe"

if not exist "%DART_EXE%" (
  echo No se encontro Flutter en "%FLUTTER_BIN%".
  echo Instala Flutter o corrige la ruta en este archivo.
  pause
  exit /b 1
)

echo Flutter: %POKESTUDIO_FLUTTER%
"%DART_EXE%" "%~dp0tool\dev_server.dart"
pause
