"""Builds dist/Ofesi-test.zip: the drive folder without the model files, plus the tester's note.
The launchers download the right model on first start. Run: python tools/make_test_zip.py"""
import pathlib, zipfile

root = pathlib.Path(__file__).resolve().parent.parent
drive, out = root / "drive", root / "dist" / "Ofesi-test.zip"

# cmd needs CRLF to find the :download label; bash needs LF.
bat, mac = drive / "START.bat", drive / "START-Mac.command"
bat.write_bytes(bat.read_bytes().replace(b"\r\n", b"\n").replace(b"\n", b"\r\n"))
mac.write_bytes(mac.read_bytes().replace(b"\r\n", b"\n"))

out.parent.mkdir(exist_ok=True)
with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
    files = [(p, p.relative_to(drive).as_posix()) for p in sorted(drive.rglob("*")) if p.is_file()]
    files.append((root / "TEST-START-HERE.txt", "TEST-START-HERE.txt"))
    for path, name in files:
        if path.suffix in (".gguf", ".part"):
            continue
        info = zipfile.ZipInfo.from_file(path, "Ofesi/" + name)
        info.compress_type = zipfile.ZIP_DEFLATED
        # Windows has no execute bit; without it macOS refuses to run the launcher.
        info.external_attr = (0o755 if path.suffix == ".command" else 0o644) << 16
        z.writestr(info, path.read_bytes())
print(out, round(out.stat().st_size / 1e6, 1), "MB")
