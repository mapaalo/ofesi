#!/bin/bash
# Ofesi for Mac: double-click to start. Close this window to stop Ofesi.
cd "$(dirname "$0")" || exit 1
PORT=8765
# Already running (or still loading)? Open that one instead of starting a second copy.
curl -s -m 2 "http://127.0.0.1:$PORT/health" >/dev/null && { open "http://127.0.0.1:$PORT/"; exit 0; }
VER=$(cat bin/VERSION.txt)
if [ "$(uname -m)" = "arm64" ]; then PKG=arm64; else PKG=x64; fi
ENGINE="$HOME/Library/Caches/Ofesi/engine-$VER-$PKG"

# exFAT drives cannot hold the engine's symlinks, so it is unpacked once into this Mac's cache.
if [ ! -x "$ENGINE/llama-server" ]; then
  echo "Preparing Ofesi for this Mac (first time only)..."
  mkdir -p "$ENGINE" && tar -xzf "bin/mac/llama-macos-$PKG.tar.gz" -C "$ENGINE" --strip-components 1 || {
    rm -rf "$ENGINE"; echo "Could not prepare Ofesi on this Mac."; read -r -p "Press Enter to close."; exit 1; }
fi

RAM=$(( $(sysctl -n hw.memsize) / 1073741824 ))
# Low-memory Macs get the small model. A copy sent without models downloads the right one once.
MODEL=models/model.gguf
[ "$RAM" -lt 12 ] && MODEL=models/small.gguf
[ -f "$MODEL" ] || { [ -f models/model.gguf ] && MODEL=models/model.gguf; }

if [ ! -f "$MODEL" ]; then
  # Official model files, pinned to one version; the checksum decides whether the download is whole.
  URL=https://huggingface.co/unsloth/Qwen3.5-9B-GGUF/resolve/3885219b6810b007914f3a7950a8d1b469d598a5/Qwen3.5-9B-Q4_K_M.gguf
  SHA=03b74727a860a56338e042c4420bb3f04b2fec5734175f4cb9fa853daf52b7e8
  SIZE=5.7
  if [ "$MODEL" = models/small.gguf ]; then
    URL=https://huggingface.co/unsloth/Qwen3.5-4B-GGUF/resolve/e87f176479d0855a907a41277aca2f8ee7a09523/Qwen3.5-4B-Q4_K_M.gguf
    SHA=00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4
    SIZE=2.7
  fi
  echo "First start: downloading the AI model, $SIZE GB. This happens once and needs internet."
  echo "If it stops, start Ofesi again and it carries on from where it stopped."
  echo
  curl -L -C - --fail -o "$MODEL.part" "$URL"
  echo; echo "Checking the download..."
  if [ "$(shasum -a 256 "$MODEL.part" 2>/dev/null | cut -d' ' -f1)" = "$SHA" ]; then
    mv "$MODEL.part" "$MODEL"
  else
    echo "The download is not complete yet. Check the internet, then start Ofesi again to continue."
    read -r -p "Press Enter to close."; exit 1
  fi
fi

if [ "$RAM" -lt 16 ] && [ "$MODEL" = models/model.gguf ]; then
  echo "WARNING: this Mac has $RAM GB of memory. Ofesi works best with 16 GB."
  echo "It may be slow. Close other apps first."
  echo
fi

echo "Starting Ofesi. Your browser will open by itself."
echo "Keep this window open while you work. Close it to stop Ofesi."
echo

# Opens the browser once the engine answers; the engine itself runs in this window.
( for _ in $(seq 600); do
    curl -s "http://127.0.0.1:$PORT/health" | grep -q '"ok"' && { open "http://127.0.0.1:$PORT/"; break; }
    sleep 1
  done ) &

# --ui-mcp-proxy lets the app fetch internet search results; --cors-origins stops other websites reading Ofesi.
"$ENGINE/llama-server" -m "$MODEL" --path app --host 127.0.0.1 --port $PORT -c 8192 --jinja --ui-mcp-proxy --cors-origins "http://127.0.0.1:$PORT" || {
  echo; echo "Ofesi could not start. If it is already open in another window, use that one."
  read -r -p "Press Enter to close."; }
