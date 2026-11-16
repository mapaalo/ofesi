@echo off
title Ofesi - keep this window open while you work
cd /d "%~dp0"
set PORT=8765

rem Already running (or still loading)? Open that one. A second copy would load the whole model again.
curl.exe -s -m 2 http://127.0.0.1:%PORT%/health >nul 2>&1
if not errorlevel 1 (
  start "" http://127.0.0.1:%PORT%/
  exit /b
)

for /f %%m in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1GB)"') do set RAM=%%m
rem Low-memory computers get the small model. A copy sent without models downloads the right one once.
set MODEL=models\model.gguf
if %RAM% LSS 12 set MODEL=models\small.gguf
if not exist %MODEL% if exist models\model.gguf set MODEL=models\model.gguf
if not exist %MODEL% call :download
if not exist %MODEL% (
  pause
  exit /b 1
)
if %RAM% LSS 12 if "%MODEL%"=="models\model.gguf" (
  echo WARNING: this computer has %RAM% GB of memory. Ofesi works best with 16 GB.
  echo It may be slow, or fail to start. Close other programs first.
  echo.
)

echo Starting Ofesi. This takes about a minute the first time.
echo Your browser will open by itself. Close this window to stop Ofesi.
echo.

rem Opens the browser once the engine answers; the engine itself runs in this window.
start "" /b powershell -NoProfile -WindowStyle Hidden -Command "for($i=0;$i -lt 600;$i++){try{if((Invoke-RestMethod http://127.0.0.1:%PORT%/health -TimeoutSec 2).status -eq 'ok'){Start-Process http://127.0.0.1:%PORT%/;break}}catch{};Start-Sleep 1}"

rem --ui-mcp-proxy lets the app fetch internet search results; --cors-origins stops other websites reading Ofesi.
bin\windows\llama-server.exe -m %MODEL% --path app --host 127.0.0.1 --port %PORT% -c 8192 --jinja --ui-mcp-proxy --cors-origins http://127.0.0.1:%PORT%
if errorlevel 1 (
  echo.
  echo Ofesi could not start. If it is already open in another window, use that one.
  pause
)
goto :eof

:download
rem Official model files, pinned to one version; the checksum decides whether the download is whole.
set URL=https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/3885219b6810b007914f3a7950a8d1b469d598a5/Qwen3.5-9B-Q4_K_M.gguf
set SHA=03b74727a860a56338e042c4420bb3f04b2fec5734175f4cb9fa853daf52b7e8
set SIZE=5.7
if "%MODEL%"=="models\small.gguf" set URL=https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/e87f176479d0855a907a41277aca2f8ee7a09523/Qwen3.5-4B-Q4_K_M.gguf
if "%MODEL%"=="models\small.gguf" set SHA=00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4
if "%MODEL%"=="models\small.gguf" set SIZE=2.7
echo First start: downloading the AI model, %SIZE% GB. This happens once and needs internet.
echo If it stops, start Ofesi again and it carries on from where it stopped.
echo.
curl.exe -L -C - --fail -o %MODEL%.part %URL%
echo.
echo Checking the download...
set GOT=
for /f %%h in ('powershell -NoProfile -Command "(Get-FileHash -Algorithm SHA256 '%MODEL%.part').Hash.ToLower()"') do set GOT=%%h
if "%GOT%"=="%SHA%" (
  move /y %MODEL%.part %MODEL% >nul
) else (
  echo The download is not complete yet. Check the internet, then start Ofesi again to continue.
)
goto :eof
