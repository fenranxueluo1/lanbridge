package com.lanbridge.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Bundle
import android.os.Environment
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private var notificationPermissionRequested = false

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val permissions = mutableListOf<String>()
        if (Build.VERSION.SDK_INT >= 33) {
            permissions.add(Manifest.permission.NEARBY_WIFI_DEVICES)
        }
        if (Build.VERSION.SDK_INT >= 36) {
            permissions.add("android.permission.ACCESS_LOCAL_NETWORK")
        }
        if (permissions.isNotEmpty()) {
            requestPermissions(permissions.toTypedArray(), 9003)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "lanbridge/network",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "acquireMulticastLock" -> {
                    try {
                        val wifi =
                            applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
                        if (multicastLock == null) {
                            multicastLock = wifi.createMulticastLock("lanbridge").apply {
                                setReferenceCounted(false)
                                acquire()
                            }
                        }
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("MULTICAST_LOCK", error.message, null)
                    }
                }
                "releaseMulticastLock" -> {
                    try {
                        multicastLock?.release()
                        multicastLock = null
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("MULTICAST_LOCK", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "lanbridge/background",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    try {
                        requestNotificationPermissionIfNeeded()
                        startTransferService()
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("BACKGROUND_START", error.message, null)
                    }
                }
                "stop" -> {
                    try {
                        stopService(Intent(this, BackgroundTransferService::class.java))
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("BACKGROUND_STOP", error.message, null)
                    }
                }
                "notifyComplete" -> {
                    try {
                        val title = call.argument<String>("title") ?: "邻传"
                        val body = call.argument<String>("body") ?: ""
                        showCompletionNotification(title, body)
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("NOTIFY_COMPLETE", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "lanbridge/storage",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "ensureManageStorage" -> result.success(ensureManageStorage())
                "hasManageStorage" -> result.success(hasManageStorage())
                else -> result.notImplemented()
            }
        }
    }

    private fun hasManageStorage(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) ==
                PackageManager.PERMISSION_GRANTED
        }
    }

    private fun ensureManageStorage(): Boolean {
        if (hasManageStorage()) return true
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                val intent = Intent(
                    Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION,
                    Uri.parse("package:$packageName"),
                )
                startActivity(intent)
            } else {
                requestPermissions(
                    arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE),
                    9002,
                )
            }
        } catch (_: Exception) {
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                    startActivity(Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION))
                }
            } catch (_: Exception) {
                // The user can grant access from system settings manually.
            }
        }
        return false
    }

    private fun startTransferService() {
        val intent = Intent(this, BackgroundTransferService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun requestNotificationPermissionIfNeeded() {
        if (Build.VERSION.SDK_INT < 33) return
        if (checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
            PackageManager.PERMISSION_GRANTED
        ) {
            return
        }
        if (notificationPermissionRequested) return
        notificationPermissionRequested = true
        requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 9001)
    }

    private fun showCompletionNotification(title: String, body: String) {
        requestNotificationPermissionIfNeeded()
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            if (manager.getNotificationChannel(COMPLETE_CHANNEL_ID) == null) {
                manager.createNotificationChannel(
                    NotificationChannel(
                        COMPLETE_CHANNEL_ID,
                        "LANBridge complete",
                        NotificationManager.IMPORTANCE_DEFAULT,
                    ).apply {
                        description = "Transfer completion notifications"
                        setShowBadge(true)
                    },
                )
            }
        }
        val openApp = PendingIntent.getActivity(
            this,
            1,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, COMPLETE_CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(title)
            .setContentText(body)
            .setAutoCancel(true)
            .setContentIntent(openApp)
            .setCategory(Notification.CATEGORY_STATUS)
            .build()
        manager.notify(COMPLETE_NOTIFICATION_ID, notification)
    }

    override fun onDestroy() {
        multicastLock?.release()
        multicastLock = null
        super.onDestroy()
    }

    companion object {
        private const val COMPLETE_CHANNEL_ID = "lanbridge_complete"
        private const val COMPLETE_NOTIFICATION_ID = 1002
    }
}
