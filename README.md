<div align="center">

<img src="https://img.shields.io/badge/nexvpn__flutter-1.0.0-blue?style=for-the-badge&logo=flutter&logoColor=white" />

# 💙 nexvpn_flutter

**Flutter plugin for NexVPN — OpenVPN integration for Android & iOS**

[![pub.dev](https://img.shields.io/pub/v/nexvpn_flutter?style=flat-square&color=blue&logo=dart)](https://pub.dev/packages/nexvpn_flutter)
[![License](https://img.shields.io/badge/License-Apache_2.0-blue?style=flat-square)](https://opensource.org/licenses/Apache-2.0)
[![Android](https://img.shields.io/badge/Android-21+-green?style=flat-square&logo=android)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-13+-black?style=flat-square&logo=apple)](https://developer.apple.com)

[Installation](#-installation) · [Setup](#-setup) · [Usage](#-usage) · [API](#-api) · [Android Library](https://github.com/nexdeve/nexvpn)

</div>

---

## ✨ Features

- 💙 **Flutter First** — clean Dart API with streams
- 🤖 **Android** — full OpenVPN via NexVPN Android library
- 🍎 **iOS** — NetworkExtension based VPN
- 📡 **Live Streams** — `stateStream` & `statsStream` for reactive UI
- 📁 **Asset or String** — load `.ovpn` either way

---

## 📦 Installation

```yaml
# pubspec.yaml
dependencies:
  nexvpn_flutter: ^1.0.0
```

```bash
flutter pub get
```

---

## ⚙️ Setup

### Android

**`android/app/build.gradle`**
```gradle
android {
    packaging {
        jniLibs { useLegacyPackaging = true }
    }
}
```

**`AndroidManifest.xml`**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_SYSTEM_EXEMPTED" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

### iOS

**`ios/Runner/Info.plist`**
```xml
<key>NEVPNEnabled</key>
<true/>
```

Enable **Network Extensions** capability in Xcode.

---

## 💡 Usage

```dart
import 'package:nexvpn_flutter/nexvpn_flutter.dart';

class _MyState extends State<MyPage> {
  final NexVpn _vpn = NexVpn();
  late StreamSubscription _stateSub;
  late StreamSubscription _statsSub;

  @override
  void initState() {
    super.initState();

    // Attach profile
    _vpn.attachFromAsset('assets/server.ovpn',
        username: 'user', password: 'pass');

    // Listen to connection state
    _stateSub = _vpn.stateStream.listen((state) {
      print(state); // VpnState.connected / disconnected / etc.
    });

    // Listen to live speed stats
    _statsSub = _vpn.statsStream.listen((stats) {
      print(VpnStats.formatSpeed(stats.downloadSpeed)); // "2.1 MB/s"
      print(VpnStats.formatBytes(stats.downloadBytes)); // "128 MB"
    });
  }

  Future<void> connect() async {
    if (!await _vpn.hasVpnPermission()) {
      await _vpn.requestVpnPermission();
      return;
    }
    await _vpn.startVpn();
  }

  @override
  void dispose() {
    _stateSub.cancel();
    _statsSub.cancel();
    _vpn.release();
    super.dispose();
  }
}
```

---

## 📖 API

### Profile Setup

| Method | Description |
|--------|-------------|
| `attachFromAsset(path, {username, password})` | Load `.ovpn` from Flutter assets |
| `attachFromString(config, {username, password})` | Load `.ovpn` from String |

### Control

| Method | Description |
|--------|-------------|
| `startVpn()` | Start VPN |
| `stopVpn()` | Stop VPN |
| `release()` | Free resources (call in `dispose()`) |

### Streams

| Stream | Type | Description |
|--------|------|-------------|
| `stateStream` | `Stream<VpnState>` | Real-time connection state |
| `statsStream` | `Stream<VpnStats>` | Speed & usage every second |

### VpnState enum

```dart
enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}
```

### VpnStats

```dart
stats.downloadBytes   // Total bytes downloaded
stats.uploadBytes     // Total bytes uploaded
stats.downloadSpeed   // Bytes/sec download
stats.uploadSpeed     // Bytes/sec upload

VpnStats.formatSpeed(stats.downloadSpeed) // "1.5 MB/s"
VpnStats.formatBytes(stats.downloadBytes) // "256 MB"
```

---

## 🌐 Also Available

| Platform | Package |
|----------|---------|
| 🤖 Android | [nexvpn](https://github.com/nexdeve/nexvpn) |
| 💙 Flutter (this) | `nexvpn_flutter` |
| 🐍 Python | Coming soon |

---

## 📄 License

```
Copyright 2026 NexTech — Apache License 2.0
```

<div align="center">
Made with ❤️ by <a href="https://github.com/nexdeve">NexDeve</a>
</div>
