library nexvpn_flutter;

import 'dart:async';
import 'package:flutter/services.dart';

/// VPN connection states
enum VpnState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error,
}

/// Speed & usage statistics
class VpnStats {
  final int downloadBytes;
  final int uploadBytes;
  final int downloadSpeed;
  final int uploadSpeed;

  const VpnStats({
    required this.downloadBytes,
    required this.uploadBytes,
    required this.downloadSpeed,
    required this.uploadSpeed,
  });

  factory VpnStats.fromMap(Map<dynamic, dynamic> map) {
    return VpnStats(
      downloadBytes: map['downloadBytes'] ?? 0,
      uploadBytes:   map['uploadBytes']   ?? 0,
      downloadSpeed: map['downloadSpeed'] ?? 0,
      uploadSpeed:   map['uploadSpeed']   ?? 0,
    );
  }

  /// Format bytes/sec → "1.5 MB/s"
  static String formatSpeed(int bytesPerSec) {
    if (bytesPerSec < 1024) return '$bytesPerSec B/s';
    if (bytesPerSec < 1024 * 1024) return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    if (bytesPerSec < 1024 * 1024 * 1024) return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
    return '${(bytesPerSec / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }

  /// Format total bytes → "256 MB"
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  @override
  String toString() =>
      '↓ ${formatSpeed(downloadSpeed)}  ↑ ${formatSpeed(uploadSpeed)} | '
      'Total: ${formatBytes(downloadBytes + uploadBytes)}';
}

/// NexVPN Flutter Plugin
///
/// Example usage:
/// ```dart
/// final vpn = NexVpn();
/// await vpn.attachFromString(ovpnConfig, username: 'user', password: 'pass');
/// vpn.stateStream.listen((state) => print(state));
/// vpn.statsStream.listen((stats) => print(stats));
/// await vpn.startVpn();
/// ```
class NexVpn {
  static const MethodChannel _channel =
      MethodChannel('ai.nextech/nexvpn');
  static const EventChannel _stateChannel =
      EventChannel('ai.nextech/nexvpn_state');
  static const EventChannel _statsChannel =
      EventChannel('ai.nextech/nexvpn_stats');

  // ─── Streams ───────────────────────────────────────────────────────────────

  /// Stream of VPN state changes
  Stream<VpnState> get stateStream {
    return _stateChannel.receiveBroadcastStream().map((event) {
      switch (event as String) {
        case 'CONNECTED':    return VpnState.connected;
        case 'CONNECTING':   return VpnState.connecting;
        case 'DISCONNECTING':return VpnState.disconnecting;
        case 'ERROR':        return VpnState.error;
        default:             return VpnState.disconnected;
      }
    });
  }

  /// Stream of live speed & usage statistics
  Stream<VpnStats> get statsStream {
    return _statsChannel.receiveBroadcastStream().map(
      (event) => VpnStats.fromMap(event as Map),
    );
  }

  // ─── Profile Attachment ────────────────────────────────────────────────────

  /// Attach .ovpn config as a raw string
  Future<void> attachFromString(
    String ovpnConfig, {
    String username = '',
    String password = '',
  }) async {
    await _channel.invokeMethod('attachFromString', {
      'config':   ovpnConfig,
      'username': username,
      'password': password,
    });
  }

  /// Attach .ovpn config from Flutter assets
  /// Put your .ovpn file in `assets/` and declare it in pubspec.yaml
  Future<void> attachFromAsset(
    String assetPath, {
    String username = '',
    String password = '',
  }) async {
    final config = await rootBundle.loadString(assetPath);
    await attachFromString(config, username: username, password: password);
  }

  // ─── Permissions ───────────────────────────────────────────────────────────

  /// Check if VPN permission is granted
  Future<bool> hasVpnPermission() async {
    return await _channel.invokeMethod<bool>('hasVpnPermission') ?? false;
  }

  /// Request VPN permission from the user
  Future<bool> requestVpnPermission() async {
    return await _channel.invokeMethod<bool>('requestVpnPermission') ?? false;
  }

  /// Check notification permission (Android 13+)
  Future<bool> hasNotificationPermission() async {
    return await _channel.invokeMethod<bool>('hasNotificationPermission') ?? true;
  }

  /// Request notification permission (Android 13+)
  Future<void> requestNotificationPermission() async {
    await _channel.invokeMethod('requestNotificationPermission');
  }

  // ─── VPN Control ───────────────────────────────────────────────────────────

  /// Start the VPN connection
  Future<void> startVpn() async {
    await _channel.invokeMethod('startVpn');
  }

  /// Stop the VPN connection
  Future<void> stopVpn() async {
    await _channel.invokeMethod('stopVpn');
  }

  /// Get the current VPN state
  Future<VpnState> getCurrentState() async {
    final state = await _channel.invokeMethod<String>('getCurrentState');
    switch (state) {
      case 'CONNECTED':    return VpnState.connected;
      case 'CONNECTING':   return VpnState.connecting;
      case 'DISCONNECTING':return VpnState.disconnecting;
      case 'ERROR':        return VpnState.error;
      default:             return VpnState.disconnected;
    }
  }

  /// Check if currently connected
  Future<bool> isConnected() async {
    return await _channel.invokeMethod<bool>('isConnected') ?? false;
  }

  /// Release resources — call in dispose()
  Future<void> release() async {
    await _channel.invokeMethod('release');
  }
}
