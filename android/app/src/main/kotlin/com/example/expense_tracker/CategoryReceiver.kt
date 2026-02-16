package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.app.NotificationManager
import android.util.Log
import android.widget.Toast

class CategoryReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "CATEGORY_SELECTED") {
            val category = intent.getStringExtra("category") ?: "Others"
            val transactionId = intent.getIntExtra("transaction_id", -1)
            val amount = intent.getDoubleExtra("amount", 0.0)
            val merchant = intent.getStringExtra("merchant") ?: "Unknown"
            
            Log.d("CategoryReceiver", "Category selected: $category for transaction $transactionId")
            
            // Dismiss the notification
            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(transactionId)
            
            // Send category selection to Flutter
            val categoryMap = mapOf(
                "transaction_id" to transactionId.toString(),
                "category" to category,
                "amount" to amount,
                "merchant" to merchant
            )
            
            MainActivity.eventSink?.success(categoryMap)
            
            // Show toast confirmation
            Toast.makeText(context, "Categorized as $category", Toast.LENGTH_SHORT).show()
        }
    }
}