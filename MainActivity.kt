package com.example.expense_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.provider.Settings
import android.content.Context
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.Manifest
import android.content.pm.PackageManager
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.app.NotificationManager
import android.app.NotificationChannel
import android.app.PendingIntent
import androidx.core.app.NotificationCompat
import android.graphics.Color
import android.util.Log
import org.json.JSONObject

class MainActivity: FlutterActivity() {
    private val CHANNEL = "notification_listener_channel"
    private val OVERLAY_PERMISSION_REQ_CODE = 1234
    private val NOTIFICATION_PERMISSION_CODE = 1001

    companion object {
        const val TRANSACTION_CHANNEL = "transaction_stream"
        var eventSink: EventChannel.EventSink? = null
    }

    // ✅ MISSING: onCreate and onNewIntent for opening categories from notifications
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent?) {
        intent?.getStringExtra("open_category")?.let { category ->
            Handler(Looper.getMainLooper()).postDelayed({
                flutterEngine?.dartExecutor?.binaryMessenger?.let { messenger ->
                    MethodChannel(messenger, CHANNEL).invokeMethod(
                        "openCategory",
                        mapOf("category" to category)
                    )
                }
            }, 500)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Check and request notification permission on Android 13+
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            if (ContextCompat.checkSelfPermission(this, Manifest.permission.POST_NOTIFICATIONS)
                != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.POST_NOTIFICATIONS),
                    NOTIFICATION_PERMISSION_CODE
                )
            }
        }

        // Method Channel for checking permissions
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "isNotificationServiceEnabled" -> {
                    result.success(isNotificationServiceEnabled())
                }
                "openNotificationSettings" -> {
                    openNotificationSettings()
                    result.success(true)
                }
                "checkOverlayPermission" -> {
                    result.success(canDrawOverlays())
                }
                "requestOverlayPermission" -> {
                    requestOverlayPermission()
                    result.success(true)
                }
                "getSavedTransactions" -> {
                    val transactions = getSavedTransactions()
                    result.success(transactions)
                }
                "saveUserData" -> {
                    val userData = call.arguments as String
                    saveUserData(userData)
                    result.success(true)
                }
                "getUserData" -> {
                    val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
                    val userData = prefs.getString("user_data", "{}")

                    // Also merge category_caps into the response
                    val categoryCaps = prefs.getString("category_caps", null)
                    if (categoryCaps != null && userData != null) {
                        try {
                            val userJson = JSONObject(userData)
                            val capsJson = JSONObject(categoryCaps)
                            userJson.put("category_caps", capsJson)
                            result.success(userJson.toString())
                            return@setMethodCallHandler
                        } catch (e: Exception) {
                            Log.e("MainActivity", "Error merging category caps: ${e.message}")
                        }
                    }

                    result.success(userData ?: "{}")
                }
                "isOnboardingCompleted" -> {
                    result.success(isOnboardingCompleted())
                }
                "saveCategoryCaps" -> {
                    val categoryCaps = call.argument<String>("categoryCaps")
                    // Save to BOTH locations for compatibility
                    val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
                    prefs.edit().putString("category_caps", categoryCaps).apply()

                    // Also save to FlutterSharedPreferences location
                    val flutterPrefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    flutterPrefs.edit().putString("flutter.category_caps", categoryCaps).apply()

                    Log.d("MainActivity", "Category caps saved: $categoryCaps")
                    result.success(true)
                }
                "showCapWarningNotification" -> {
                    try {
                        val category = call.argument<String>("category") ?: ""
                        val currentSpending = call.argument<Double>("currentSpending") ?: 0.0
                        val capAmount = call.argument<Double>("capAmount") ?: 0.0
                        val percentage = call.argument<Double>("percentage") ?: 0.0
                        val type = call.argument<String>("type") ?: "warning"

                        showCapWarningNotification(category, currentSpending, capAmount, percentage, type)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // Event Channel for streaming transactions
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, TRANSACTION_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    private fun showCapWarningNotification(
        category: String,
        currentSpending: Double,
        capAmount: Double,
        percentage: Double,
        type: String
    ) {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "spending_caps",
                "Spending Cap Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Notifications when you approach or exceed spending caps"
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val (title, message, color) = when (type) {
            "warning" -> Triple(
                "⚠️ Spending Alert: $category",
                "You've used ${percentage.toInt()}% (₹${currentSpending.toInt()}/₹${capAmount.toInt()}) of your $category budget",
                Color.parseColor("#FF9800")
            )
            else -> Triple(
                "🚨 Budget Exceeded: $category",
                "You've exceeded your $category cap! ₹${currentSpending.toInt()}/₹${capAmount.toInt()} (${percentage.toInt()}%)",
                Color.parseColor("#F44336")
            )
        }

        // ✅ MISSING: PendingIntent to open the category when notification is tapped
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            putExtra("open_category", category)
        }

        val pendingIntent = PendingIntent.getActivity(
            this,
            category.hashCode(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(this, "spending_caps")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setColor(color)
            .setVibrate(longArrayOf(0, 500, 200, 500))
            .setContentIntent(pendingIntent)  // ✅ ADDED: Makes notification clickable
            .build()

        notificationManager.notify(category.hashCode(), notification)
    }

    private fun saveUserData(userData: String) {
        val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
        prefs.edit().putString("user_data", userData).apply()
    }

    private fun getUserData(): String {
        val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
        return prefs.getString("user_data", "{}") ?: "{}"
    }

    private fun isOnboardingCompleted(): Boolean {
        val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
        val userData = prefs.getString("user_data", "{}")
        return try {
            val json = JSONObject(userData ?: "{}")
            json.optBoolean("onboarding_completed", false)
        } catch (e: Exception) {
            false
        }
    }

    private fun getSavedTransactions(): String {
        val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
        return prefs.getString("transactions", "[]") ?: "[]"
    }

    private fun isNotificationServiceEnabled(): Boolean {
        val enabledListeners = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        )
        return enabledListeners?.contains(packageName) == true
    }

    private fun openNotificationSettings() {
        val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
        startActivity(intent)
    }

    private fun canDrawOverlays(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            Settings.canDrawOverlays(this)
        } else {
            true
        }
    }

    private fun requestOverlayPermission() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            val intent = Intent(
                Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                Uri.parse("package:$packageName")
            )
            startActivityForResult(intent, OVERLAY_PERMISSION_REQ_CODE)
        }
    }
}