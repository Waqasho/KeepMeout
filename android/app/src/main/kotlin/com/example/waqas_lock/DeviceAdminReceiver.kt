package com.example.waqas_lock; // Apna package name check kar lein

import android.app.admin.DeviceAdminReceiver;
import android.content.Context;
import android.content.Intent;
import android.widget.Toast;

// Class ka naam "DeviceAdminReceiver" rakha gaya hai jaisa aapke Manifest file mein hai
public class DeviceAdminReceiver extends android.app.admin.DeviceAdminReceiver {
    @Override
    public void onEnabled(Context context, Intent intent) {
        super.onEnabled(context, intent);
        Toast.makeText(context, "Device Admin: Enabled", Toast.LENGTH_SHORT).show();
    }

    @Override
    public void onDisabled(Context context, Intent intent) {
        super.onDisabled(context, intent);
        Toast.makeText(context, "Device Admin: Disabled", Toast.LENGTH_SHORT).show();
    }
}
