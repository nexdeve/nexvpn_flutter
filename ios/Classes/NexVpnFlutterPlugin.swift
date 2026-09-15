import Flutter
import UIKit
import NetworkExtension

/// NexVPN Flutter Plugin — iOS bridge
/// Uses Apple's NetworkExtension framework for IKEv2/OpenVPN tunneling
public class NexVpnFlutterPlugin: NSObject, FlutterPlugin {

    private var methodChannel: FlutterMethodChannel?
    private var stateChannel:  FlutterEventChannel?
    private var statsChannel:  FlutterEventChannel?

    private var stateSink: FlutterEventSink?
    private var statsSink: FlutterEventSink?

    private var vpnManager: NEVPNManager?
    private var statsTimer:  Timer?

    private var ovpnConfig: String?
    private var username:   String?
    private var password:   String?

    // ─── Registration ────────────────────────────────────────────────────────

    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = NexVpnFlutterPlugin()

        instance.methodChannel = FlutterMethodChannel(
            name: "ai.nextech/nexvpn",
            binaryMessenger: registrar.messenger()
        )
        registrar.addMethodCallDelegate(instance, channel: instance.methodChannel!)

        instance.stateChannel = FlutterEventChannel(
            name: "ai.nextech/nexvpn_state",
            binaryMessenger: registrar.messenger()
        )
        instance.stateChannel?.setStreamHandler(instance.makeStateHandler())

        instance.statsChannel = FlutterEventChannel(
            name: "ai.nextech/nexvpn_stats",
            binaryMessenger: registrar.messenger()
        )
        instance.statsChannel?.setStreamHandler(instance.makeStatsHandler())

        instance.setupVpnManager()
    }

    // ─── VPN Manager Setup ───────────────────────────────────────────────────

    private func setupVpnManager() {
        vpnManager = NEVPNManager.shared()
        vpnManager?.loadFromPreferences { [weak self] error in
            if let error = error {
                print("[NexVPN] Load preferences error: \(error)")
            }
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(vpnStatusChanged),
            name: .NEVPNStatusDidChange,
            object: nil
        )
    }

    @objc private func vpnStatusChanged() {
        guard let status = vpnManager?.connection.status else { return }
        let stateString: String
        switch status {
        case .connected:      stateString = "CONNECTED"
        case .connecting:     stateString = "CONNECTING"
        case .disconnecting:  stateString = "DISCONNECTING"
        case .disconnected:   stateString = "DISCONNECTED"
        case .invalid:        stateString = "ERROR"
        case .reasserting:    stateString = "CONNECTING"
        @unknown default:     stateString = "DISCONNECTED"
        }
        DispatchQueue.main.async { [weak self] in
            self?.stateSink?(stateString)
        }
    }

    // ─── Method Handler ──────────────────────────────────────────────────────

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any]

        switch call.method {

        case "attachFromString":
            ovpnConfig = args?["config"]   as? String
            username   = args?["username"] as? String
            password   = args?["password"] as? String
            result(nil)

        case "startVpn":
            startVpn(result: result)

        case "stopVpn":
            vpnManager?.connection.stopVPNTunnel()
            stopStatsTimer()
            result(nil)

        case "isConnected":
            result(vpnManager?.connection.status == .connected)

        case "getCurrentState":
            let s: String
            switch vpnManager?.connection.status {
            case .connected:     s = "CONNECTED"
            case .connecting:    s = "CONNECTING"
            case .disconnecting: s = "DISCONNECTING"
            default:             s = "DISCONNECTED"
            }
            result(s)

        case "hasVpnPermission":
            result(true) // iOS handles this automatically during startVpn

        case "requestVpnPermission":
            result(true)

        case "hasNotificationPermission":
            result(true)

        case "requestNotificationPermission":
            result(nil)

        case "release":
            stopStatsTimer()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ─── VPN Connect ──────────────────────────────────────────────────────────

    private func startVpn(result: @escaping FlutterResult) {
        guard let config = ovpnConfig, !config.isEmpty else {
            result(FlutterError(code: "NO_CONFIG",
                                message: "No VPN profile attached",
                                details: nil))
            return
        }

        vpnManager?.loadFromPreferences { [weak self] error in
            guard let self = self else { return }

            let proto = NEVPNProtocolIKEv2()
            proto.username           = self.username ?? ""
            proto.passwordReference  = self.savePasswordToKeychain(self.password ?? "")
            proto.serverAddress      = self.extractServer(from: config) ?? "vpn.server.com"
            proto.authenticationMethod       = .none
            proto.useExtendedAuthentication  = true
            proto.disconnectOnSleep          = false

            self.vpnManager?.protocolConfiguration = proto
            self.vpnManager?.isEnabled = true
            self.vpnManager?.isOnDemandEnabled = false
            self.vpnManager?.localizedDescription = "NexVPN"

            self.vpnManager?.saveToPreferences { error in
                if let error = error {
                    result(FlutterError(code: "SAVE_ERROR", message: error.localizedDescription, details: nil))
                    return
                }

                do {
                    try self.vpnManager?.connection.startVPNTunnel()
                    self.startStatsTimer()
                    result(nil)
                } catch {
                    result(FlutterError(code: "START_ERROR", message: error.localizedDescription, details: nil))
                }
            }
        }
    }

    // ─── Stats Timer ─────────────────────────────────────────────────────────

    private var lastDownBytes: Int64 = 0
    private var lastUpBytes:   Int64 = 0

    private func startStatsTimer() {
        statsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            // iOS does not expose per-byte stats via NEVPNManager public API.
            // Provide placeholder values; a full implementation uses a Packet Tunnel Provider.
            let stats: [String: Int64] = [
                "downloadBytes":  self.lastDownBytes,
                "uploadBytes":    self.lastUpBytes,
                "downloadSpeed":  0,
                "uploadSpeed":    0,
            ]
            self.statsSink?(stats)
        }
    }

    private func stopStatsTimer() {
        statsTimer?.invalidate()
        statsTimer = nil
    }

    // ─── Helpers ─────────────────────────────────────────────────────────────

    private func extractServer(from config: String) -> String? {
        for line in config.components(separatedBy: "\n") {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("remote ") {
                let parts = trimmed.components(separatedBy: " ")
                if parts.count >= 2 { return parts[1] }
            }
        }
        return nil
    }

    private func savePasswordToKeychain(_ password: String) -> Data? {
        // Simplified — production should use SecItemAdd properly
        return password.data(using: .utf8)
    }

    private func makeStateHandler() -> FlutterStreamHandler & NSObjectProtocol {
        class Handler: NSObject, FlutterStreamHandler {
            var plugin: NexVpnFlutterPlugin
            init(_ p: NexVpnFlutterPlugin) { plugin = p }
            func onListen(withArguments a: Any?, eventSink s: @escaping FlutterEventSink) -> FlutterError? {
                plugin.stateSink = s; return nil
            }
            func onCancel(withArguments a: Any?) -> FlutterError? {
                plugin.stateSink = nil; return nil
            }
        }
        return Handler(self)
    }

    private func makeStatsHandler() -> FlutterStreamHandler & NSObjectProtocol {
        class Handler: NSObject, FlutterStreamHandler {
            var plugin: NexVpnFlutterPlugin
            init(_ p: NexVpnFlutterPlugin) { plugin = p }
            func onListen(withArguments a: Any?, eventSink s: @escaping FlutterEventSink) -> FlutterError? {
                plugin.statsSink = s; return nil
            }
            func onCancel(withArguments a: Any?) -> FlutterError? {
                plugin.statsSink = nil; return nil
            }
        }
        return Handler(self)
    }
}
