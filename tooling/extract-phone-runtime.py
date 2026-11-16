"""Restore the Android runtime build inputs from a matching, trusted APK."""

import json
from pathlib import Path
import shutil
import sys
import zipfile


ROOT = Path(__file__).resolve().parent.parent
ABI = "arm64-v8a"
ASSETS = "assets/runtime/"


def extract_runtime(apk):
    bundle = ROOT / "runtime" / "out" / ABI
    tawcroot = ROOT / "runtime" / "out-tawcroot" / "jniLibs" / ABI
    with zipfile.ZipFile(apk) as archive:
        manifest = json.loads(archive.read(f"{ASSETS}manifest.json"))
        if manifest["abi"] != ABI:
            raise ValueError(f"Expected an {ABI} APK")

        def copy(member, target):
            target.parent.mkdir(parents=True, exist_ok=True)
            with archive.open(member) as source, target.open("wb") as result:
                shutil.copyfileobj(source, result)

        for member in archive.infolist():
            name = member.filename
            if name.startswith(ASSETS) and not member.is_dir():
                relative = Path(name)
                if relative.is_absolute() or ".." in relative.parts or "\\" in name:
                    raise ValueError(f"Invalid runtime asset: {name}")
                copy(member, bundle / relative)
        for name in manifest["jniLibs"]:
            if Path(name).name != name or not name.startswith("lib") or not name.endswith(".so"):
                raise ValueError(f"Invalid JNI filename: {name}")
            copy(f"lib/{ABI}/{name}", bundle / "jniLibs" / ABI / name)
        copy(f"lib/{ABI}/libtawcroot.so", tawcroot / "libtawcroot.so")


if __name__ == "__main__":
    extract_runtime(sys.argv[1])
