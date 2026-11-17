# Ofesi

An offline office team for people who run a business on their own. Six AI staff
(letters, quotes and invoices, marketing posts, bookkeeping help, customer replies
and planning) run on the owner's own laptop through llama.cpp. No account, no
subscription and no internet needed; business details and chats stay in the
browser on that computer. Online news search is optional and off by default.

Made by Stormbox Creative Studio, Lusaka.

## Run it

1. Put the llama.cpp engine (release `b12262`, see `drive/bin/VERSION.txt`) in place:
   - Windows: the contents of the CPU x64 zip into `drive/bin/windows/`
   - Mac: `llama-macos-arm64.tar.gz` and `llama-macos-x64.tar.gz` into `drive/bin/mac/`

   Or take the ready-made zip from this repo's Releases.
2. Windows: double-click `drive/START.bat`. Mac: double-click `drive/START-Mac.command`.
3. On first start the launcher downloads the model (Qwen3.5 9B, or 4B on machines
   under 12 GB of RAM), checks its SHA-256 and opens Ofesi at http://127.0.0.1:8765.

End-user instructions are in `drive/README.txt`.

## Layout

| Path | What it is |
|---|---|
| `drive/app/index.html` | The whole app, one file |
| `drive/START.bat`, `drive/START-Mac.command` | Launchers (keep CRLF on the .bat) |
| `drive/models/` | Model download target and model licence |
| `tools/make_test_zip.py` | Builds `dist/Ofesi-test.zip` without the model |
| `tools/pad_rope_sections.py` | Makes an Ollama Qwen3.5 GGUF load in upstream llama.cpp |

## Licences

llama.cpp is MIT (`drive/bin/LLAMA_CPP_LICENSE.txt`); Qwen3.5 weights are Apache 2.0
(`drive/models/MODEL_LICENSE.txt`). Ofesi's own code: copyright Stormbox Creative Studio, all rights reserved.
The source is public to read; no licence is granted to copy, modify or redistribute it.
