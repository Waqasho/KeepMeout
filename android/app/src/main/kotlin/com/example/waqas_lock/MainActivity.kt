package com.example.waqas_lock; // Apna package name check kar lein

import android.app.admin.DevicePolicyManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import androidx.annotation.NonNull;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.example.waqas_lock/device_admin";
    private DevicePolicyManager devicePolicyManager;
    private ComponentName deviceAdminComponent;
    private static final int REQUEST_CODE_ENABLE_ADMIN = 1;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);

        // System services aur components ko initialize karein
        devicePolicyManager = (DevicePolicyManager) getSystemService(Context.DEVICE_POLICY_SERVICE);
        // Yahan "DeviceAdminReceiver.class" istemal kiya gaya hai
        deviceAdminComponent = new ComponentName(this, DeviceAdminReceiver.class);

        // MethodChannel set up karein jo Flutter se baat karega
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler(
                        (call, result) -> {
                            switch (call.method) {
                                case "isDeviceAdminActive":
                                    result.success(isDeviceAdminActive());
                                    break;
                                case "requestDeviceAdmin":
                                    requestDeviceAdmin();
                                    result.success(null);
                                    break;
                                case "lockScreen":
                                    if (isDeviceAdminActive()) {
                                        devicePolicyManager.lockNow();
                                        result.success(true);
                                    } else {
                                        result.success(false);
                                    }
                                    break;
                                default:
                                    result.notImplemented();
                            }
                        }
                );
    }

    private boolean isDeviceAdminActive() {
        return devicePolicyManager.isAdminActive(deviceAdminComponent);
    }

    private void requestDeviceAdmin() {
        if (!isDeviceAdminActive()) {
            Intent intent = new Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN);
            intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, deviceAdminComponent);
            intent.putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                    "This permission is required to automatically lock the screen and prevent uninstallation.");
            startActivityForResult(intent, REQUEST_CODE_ENABLE_ADMIN);
        }
    }
}
