import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nexvpn_flutter/nexvpn_flutter.dart';

void main() {
  runApp(const NexVpnExampleApp());
}

class NexVpnExampleApp extends StatelessWidget {
  const NexVpnExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NexVPN Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        useMaterial3: true,
      ),
      home: const VpnHomePage(),
    );
  }
}

class VpnHomePage extends StatefulWidget {
  const VpnHomePage({super.key});

  @override
  State<VpnHomePage> createState() => _VpnHomePageState();
}

class _VpnHomePageState extends State<VpnHomePage> {
  final NexVpn _nexVpn = NexVpn();

  VpnState _state  = VpnState.disconnected;
  VpnStats? _stats;
  String _statusText = 'Disconnected';

  StreamSubscription<VpnState>? _stateSub;
  StreamSubscription<VpnStats>? _statsSub;

  @override
  void initState() {
    super.initState();
    _initVpn();
  }

  Future<void> _initVpn() async {
    // Request notification permission
    if (!await _nexVpn.hasNotificationPermission()) {
      await _nexVpn.requestNotificationPermission();
    }

    // Attach your .ovpn profile
    // Option 1: From assets
    // await _nexVpn.attachFromAsset('assets/server.ovpn', username: 'user', password: 'pass');

    // Option 2: From string (example inline config)
    await _nexVpn.attachFromString(
      '''client
dev tun
proto udp
remote vpn.example.com 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3''',
      username: 'nexuser',
      password: 'nexpass',
    );

    // Listen to state changes
    _stateSub = _nexVpn.stateStream.listen((state) {
      setState(() {
        _state = state;
        _statusText = switch (state) {
          VpnState.connected     => 'Connected',
          VpnState.connecting    => 'Connecting…',
          VpnState.disconnecting => 'Disconnecting…',
          VpnState.error         => 'Error',
          VpnState.disconnected  => 'Disconnected',
        };
      });
    });

    // Listen to speed/usage stats
    _statsSub = _nexVpn.statsStream.listen((stats) {
      setState(() => _stats = stats);
    });
  }

  Future<void> _toggleVpn() async {
    if (_state == VpnState.connected) {
      await _nexVpn.stopVpn();
    } else {
      if (!await _nexVpn.hasVpnPermission()) {
        await _nexVpn.requestVpnPermission();
        return;
      }
      await _nexVpn.startVpn();
    }
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _statsSub?.cancel();
    _nexVpn.release();
    super.dispose();
  }

  // ─── UI ────────────────────────────────────────────────────────────────────

  Color get _stateColor => switch (_state) {
    VpnState.connected    => const Color(0xFF34A853),
    VpnState.connecting   => const Color(0xFFFBBC04),
    VpnState.error        => const Color(0xFFEA4335),
    _                     => const Color(0xFF9AA0A6),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1117),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── Status orb ──────────────────────────────────────
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _stateColor.withOpacity(0.15),
                  border: Border.all(color: _stateColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: _stateColor.withOpacity(0.4),
                      blurRadius: _state == VpnState.connected ? 40 : 10,
                      spreadRadius: _state == VpnState.connected ? 10 : 0,
                    ),
                  ],
                ),
                child: Icon(
                  _state == VpnState.connected
                      ? Icons.lock
                      : Icons.lock_open,
                  size: 64,
                  color: _stateColor,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // ── Status text ─────────────────────────────────────
            Text(
              _statusText,
              style: TextStyle(
                color: _stateColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 48),

            // ── Stats card ──────────────────────────────────────
            if (_state == VpnState.connected && _stats != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C2128),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF30363D)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                        icon: Icons.arrow_downward,
                        label: 'Download',
                        value: VpnStats.formatSpeed(_stats!.downloadSpeed),
                        color: const Color(0xFF34A853),
                      ),
                      _StatItem(
                        icon: Icons.arrow_upward,
                        label: 'Upload',
                        value: VpnStats.formatSpeed(_stats!.uploadSpeed),
                        color: const Color(0xFF1A73E8),
                      ),
                      _StatItem(
                        icon: Icons.data_usage,
                        label: 'Usage',
                        value: VpnStats.formatBytes(
                          _stats!.downloadBytes + _stats!.uploadBytes,
                        ),
                        color: const Color(0xFFFBBC04),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 48),

            // ── Connect button ──────────────────────────────────
            GestureDetector(
              onTap: _state == VpnState.connecting || _state == VpnState.disconnecting
                  ? null
                  : _toggleVpn,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 56,
                decoration: BoxDecoration(
                  color: _stateColor,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: _stateColor.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _state == VpnState.connected ? 'Disconnect' : 'Connect',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF8B949E), fontSize: 11)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
