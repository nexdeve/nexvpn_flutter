package ai.nextech.nexvpn_flutter;

import android.app.Activity;
import android.content.Context;

import androidx.annotation.NonNull;

import java.util.HashMap;
import java.util.Map;

import ai.nextech.nexvpn.NexVpn;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * NexVPN Flutter Plugin — Android bridge
 */
public class NexVpnFlutterPlugin implements FlutterPlugin, MethodCallHandler, ActivityAware {

    private static final String METHOD_CHANNEL = "ai.nextech/nexvpn";
    private static final String STATE_CHANNEL  = "ai.nextech/nexvpn_state";
    private static final String STATS_CHANNEL  = "ai.nextech/nexvpn_stats";

    private MethodChannel methodChannel;
    private EventChannel  stateEventChannel;
    private EventChannel  statsEventChannel;

    private EventChannel.EventSink stateSink;
    private EventChannel.EventSink statsSink;

    private Context  context;
    private Activity activity;
    private NexVpn   nexVpn;

    // ─── FlutterPlugin ────────────────────────────────────────────────────────

    @Override
    public void onAttachedToEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        context = binding.getApplicationContext();

        methodChannel = new MethodChannel(binding.getBinaryMessenger(), METHOD_CHANNEL);
        methodChannel.setMethodCallHandler(this);

        stateEventChannel = new EventChannel(binding.getBinaryMessenger(), STATE_CHANNEL);
        stateEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override public void onListen(Object args, EventChannel.EventSink sink) { stateSink = sink; }
            @Override public void onCancel(Object args) { stateSink = null; }
        });

        statsEventChannel = new EventChannel(binding.getBinaryMessenger(), STATS_CHANNEL);
        statsEventChannel.setStreamHandler(new EventChannel.StreamHandler() {
            @Override public void onListen(Object args, EventChannel.EventSink sink) { statsSink = sink; }
            @Override public void onCancel(Object args) { statsSink = null; }
        });

        initNexVpn();
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPlugin.FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        if (nexVpn != null) nexVpn.release();
    }

    // ─── ActivityAware ────────────────────────────────────────────────────────

    @Override
    public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
        activity = binding.getActivity();
    }

    @Override public void onDetachedFromActivityForConfigChanges() { activity = null; }
    @Override public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding b) { activity = b.getActivity(); }
    @Override public void onDetachedFromActivity() { activity = null; }

    // ─── NexVpn Init ──────────────────────────────────────────────────────────

    private void initNexVpn() {
        nexVpn = new NexVpn(context);
        nexVpn.setVpnListener(new NexVpn.VpnListener() {
            @Override
            public void onVpnConnected() {
                sendState("CONNECTED");
            }

            @Override
            public void onVpnStopped() {
                sendState("DISCONNECTED");
            }

            @Override
            public void onStatusUpdate(String status) {
                sendState(status);
            }

            @Override
            public void onError(String errorMessage) {
                sendState("ERROR");
                if (stateSink != null) stateSink.error("VPN_ERROR", errorMessage, null);
            }

            @Override
            public void onSpeedUpdate(long downloadBytes, long uploadBytes,
                                      long downloadSpeed, long uploadSpeed) {
                if (statsSink != null) {
                    Map<String, Long> stats = new HashMap<>();
                    stats.put("downloadBytes", downloadBytes);
                    stats.put("uploadBytes",   uploadBytes);
                    stats.put("downloadSpeed", downloadSpeed);
                    stats.put("uploadSpeed",   uploadSpeed);
                    statsSink.success(stats);
                }
            }
        });
    }

    private void sendState(String state) {
        if (stateSink != null) stateSink.success(state);
    }

    // ─── MethodCallHandler ────────────────────────────────────────────────────

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
        switch (call.method) {

            case "attachFromString":
                String config   = call.argument("config");
                String username = call.argument("username");
                String password = call.argument("password");
                nexVpn.attachFromString(
                        config   != null ? config   : "",
                        username != null ? username : "",
                        password != null ? password : ""
                );
                result.success(null);
                break;

            case "startVpn":
                nexVpn.startVpn();
                result.success(null);
                break;

            case "stopVpn":
                nexVpn.stopVpn();
                result.success(null);
                break;

            case "isConnected":
                result.success(nexVpn.isConnected());
                break;

            case "getCurrentState":
                result.success(nexVpn.getCurrentState().name().toUpperCase());
                break;

            case "hasVpnPermission":
                result.success(nexVpn.hasVpnPermission());
                break;

            case "requestVpnPermission":
                nexVpn.requestVpnPermission();
                result.success(true);
                break;

            case "hasNotificationPermission":
                result.success(nexVpn.hasNotificationPermission());
                break;

            case "requestNotificationPermission":
                nexVpn.requestNotificationPermission();
                result.success(null);
                break;

            case "release":
                nexVpn.release();
                result.success(null);
                break;

            default:
                result.notImplemented();
                break;
        }
    }
}
