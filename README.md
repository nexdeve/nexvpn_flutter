<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:01579b,100:54c5f8&height=160&section=header&text=nexvpn_flutter&fontSize=44&fontColor=ffffff&animation=fadeIn&fontAlignY=42&desc=Flutter%20VPN%20Plugin%20for%20Android%20%26%20iOS&descAlignY=62&descColor=b3e5fc" />

[![pub.dev](https://img.shields.io/pub/v/nexvpn_flutter?style=for-the-badge&color=54c5f8)](https://pub.dev/packages/nexvpn_flutter)
[![License](https://img.shields.io/badge/License-Apache_2.0-6366f1?style=for-the-badge)](https://opensource.org/licenses/Apache-2.0)
[![Android](https://img.shields.io/badge/Android-21+-10b981?style=for-the-badge&logo=android&logoColor=white)](https://developer.android.com)
[![iOS](https://img.shields.io/badge/iOS-13+-black?style=for-the-badge&logo=apple)](https://developer.apple.com)
[![Author](https://img.shields.io/badge/By-NexDeve-076AF4?style=for-the-badge)](https://nexdeve.com)

**Flutter plugin for NexVPN — easy OpenVPN for Android & iOS**
Made by [nexdeve.com](https://nexdeve.com)

[Installation](#-installation) · [Setup](#-setup) · [Usage](#-usage) · [API](#-api) · [Android Lib](https://github.com/nexdeve/nexvpn)

</div>

---

## ✨ Features

- 💙 **Flutter First** — clean Dart API with reactive streams
- 🤖 **Android** — full OpenVPN via NexVPN Android library
- 🍎 **iOS** — NetworkExtension based VPN
- 📡 **Live Streams** — `stateStream` & `statsStream`
- 📁 **Asset or String** — load `.ovpn` either way

---

## 📦 Installation

```yaml
dependencies:
  nexvpn_flutter: ^1.0.0
```

---

## ⚙️ Setup

**Android** — `app/build.gradle`:
```gradle
android {
    packaging {
        jniLibs { useLegacyPackaging = true }
    }
}
```

**iOS** — `ios/Runner/Info.plist`:
```xml
<key>NEVPNEnabled</key>
<true/>
```

---

## 💡 Usage

```dart
import 'package:nexvpn_flutter/nexvpn_flutter.dart';

final vpn = NexVpn();

await vpn.attachFromAsset('assets/server.ovpn',
    username: 'user', password: 'pass');

// Listen to state
vpn.stateStream.listen((state) {
  print(state); // VpnState.connected / disconnected / etc.
});

// Listen to live speed stats
vpn.statsStream.listen((stats) {
  print(VpnStats.formatSpeed(stats.downloadSpeed)); // "2.1 MB/s"
  print(VpnStats.formatBytes(stats.downloadBytes)); // "128 MB"
});

// Connect
if (await vpn.hasVpnPermission()) {
  await vpn.startVpn();
} else {
  await vpn.requestVpnPermission();
}

// Disconnect
await vpn.stopVpn();

// Cleanup
vpn.release();
```

---

## 📖 API

| Method / Stream | Description |
|-----------------|-------------|
| `attachFromAsset(path, {username, password})` | Load `.ovpn` from Flutter assets |
| `attachFromString(config, {username, password})` | Load from String |
| `startVpn()` | Start VPN |
| `stopVpn()` | Stop VPN |
| `isConnected()` | `Future<bool>` |
| `stateStream` | `Stream<VpnState>` — realtime state |
| `statsStream` | `Stream<VpnStats>` — speed & usage |
| `release()` | Free resources in `dispose()` |

---

## 🌐 NexVPN Ecosystem

| Platform | Repo | Install |
|----------|------|---------|
| 🤖 Android | [nexvpn](https://github.com/nexdeve/nexvpn) | `implementation 'ai.nextech:nexvpn:1.0.0'` |
| 💙 Flutter (this) | [nexvpn_flutter](https://github.com/nexdeve/nexvpn_flutter) | `nexvpn_flutter: ^1.0.0` |
| 🐍 Python | [nexvpn_python](https://github.com/nexdeve/nexvpn_python) | `pip install nexvpn` |

---

<div align="center">

<img src="https://capsule-render.vercel.app/api?type=waving&color=0:54c5f8,100:01579b&height=80&section=footer" />

Made with ❤️ by [**NexDeve**](https://nexdeve.com) · [nexdeve.com](https://nexdeve.com) · [Telegram](https://t.me/+c34_uTIBJEpkZGM9)

</div>
