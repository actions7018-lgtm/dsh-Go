# Build DSH Go Custom on an ARM64 Android phone

Use the ARM64 toolchain from [Flutter for Termux 3.47.7](https://github.com/GeneralKaos666/flutter-for-termux/releases/tag/3.47.7). Install Flutter, a JDK, the Android SDK, native `aapt2`, `apksigner`, Python and Git in Termux. Check the toolchain with `flutter doctor -v`. If needed, set `DSH_ANDROID_NDK_VERSION` to the version of the locally installed ARM64-host NDK.

Clone the source into the Termux home directory. Get a trusted full ARM64 APK whose runtime matches the source. The script extracts the runtime and `libtawcroot.so` from it, then recompiles the Flutter client and Android wrapper. If you change runtime sources, rebuild the runtime from the corresponding commit first.

Configure the persistent signing key in `app/android/key.properties`. Use an absolute path and keep the key in a private directory. Use the same key if the first Custom APK was signed in CI.

```properties
storeFile=/absolute/path/to/dsh-custom.p12
storePassword=YOUR_PASSWORD
keyAlias=dsh-custom
keyPassword=YOUR_PASSWORD
```

```sh
termux-setup-storage
bash tooling/build-on-phone.sh "$HOME/storage/downloads/base-arm64.apk"
```

Open `DSH-Go-Custom-arm64.apk` in Downloads. Keep the package ID and signing key and increase the version code for in-place upgrades. [中文](build-on-phone.md)
