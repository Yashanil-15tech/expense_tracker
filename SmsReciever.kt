package com.example.expense_tracker

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.Telephony
import android.util.Log

class SmsReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Telephony.Sms.Intents.SMS_RECEIVED_ACTION) {
            for (sms in Telephony.Sms.Intents.getMessagesFromIntent(intent)) {
                val messageBody = sms.messageBody ?: return
                val sender = sms.originatingAddress ?: ""

                Log.d("SmsReceiver", "SMS Received from $sender")
                Log.d("SmsReceiver", "Message: $messageBody")

                val helper = SmsTransactionHelper(context)
                helper.processSms(sender, messageBody)
            }
        }
    }
}
