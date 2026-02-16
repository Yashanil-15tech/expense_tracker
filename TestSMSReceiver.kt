package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class TestSmsReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == "com.example.expense_tracker.TEST_SMS") {
            val sender = intent.getStringExtra("sender") ?: "TESTBANK"
            val body = intent.getStringExtra("body") ?: ""

            Log.d("TestSmsReceiver", "===== TEST SMS RECEIVED =====")
            Log.d("TestSmsReceiver", "Sender: $sender")
            Log.d("TestSmsReceiver", "Body: $body")

            val helper = SmsTransactionHelper(context)
            helper.processSms(sender, body)
        }
    }
}