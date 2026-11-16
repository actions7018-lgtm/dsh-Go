#!/usr/bin/env bash
# Run in Termux with the ARM64 Flutter SDK, Android SDK, JDK and Python on PATH.
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$root"

if [[ $# != 1 ]]; then
  echo 'Usage: bash tooling/build-on-phone.sh /path/to/base-arm64.apk' >&2
  exit 2
fi
if [[ $(uname -m) != aarch64 || ! -x ${PREFIX:-}/bin/aapt2 ]]; then
  echo 'Use ARM64 Termux with its native aapt2.' >&2
  exit 2
fi
if [[ ! -s app/android/key.properties ]]; then
  echo 'Configure your persistent signing key in app/android/key.properties first.' >&2
  exit 2
fi

apksigner verify "$1"
python3 -I tooling/extract-phone-runtime.py "$1"
python3 app/tool/l10n_merge.py
python3 app/tool/guide_sync.py

export DSH_CUSTOM_BUILD=1
env "ORG_GRADLE_PROJECT_android.aapt2FromMavenOverride=$PREFIX/bin/aapt2" \
  bash tooling/build-apk.sh --reuse-tawcroot -- --no-tree-shake-icons \
  --dart-define=DSH_UPDATE_REPO=actions7018-lgtm/dsh-Go --dart-define=DSH_UPDATE_MIRROR=

apk=app/build/app/outputs/flutter-apk/app-arm64-release.apk
apksigner verify "$apk"
if [[ -d $HOME/storage/downloads ]]; then
  cp "$apk" "$HOME/storage/downloads/DSH-Go-Custom-arm64.apk"
  echo 'Download/DSH-Go-Custom-arm64.apk'
fi
