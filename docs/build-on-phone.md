# 在 ARM64 安卓手机本机打包 DSH Go Custom

使用 [Flutter for Termux 3.47.7](https://github.com/GeneralKaos666/flutter-for-termux/releases/tag/3.47.7) 的 ARM64 工具链。在 Termux 中准备 Flutter、JDK、Android SDK、原生 `aapt2`、`apksigner`、Python 和 Git。执行 `flutter doctor -v` 检查工具链。有需要时，用 `DSH_ANDROID_NDK_VERSION` 指定已安装的 ARM64 宿主 NDK 版本。

把源码克隆到 Termux 的用户目录。准备一份可信、与源码运行时版本匹配的完整 ARM64 APK。脚本从该包提取运行时及 `libtawcroot.so`，然后重新编译 Flutter 客户端和 Android 外壳。修改运行时源码后，需要先从对应提交重新生成运行时包。

在 `app/android/key.properties` 配置长期使用的自用版签名。密钥文件使用绝对路径并保存在私有目录。如果 Cloud build 已经签出了自用版首包，使用首包的同一套密钥。

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

在系统「下载」里打开 `DSH-Go-Custom-arm64.apk`。同一包名、同一签名和递增的版本号用于后续覆盖更新。 [English](build-on-phone.en.md)
