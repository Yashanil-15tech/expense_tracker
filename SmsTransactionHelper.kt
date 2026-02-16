package com.example.expense_tracker

import android.content.Context
import android.util.Log

class SmsTransactionHelper(private val context: Context) {
    companion object {
        private const val TAG = "SmsTransactionHelper"
    }
    
    fun processSms(sender: String, body: String) {
        Log.d(TAG, "===== PROCESSING SMS =====")
        Log.d(TAG, "Sender: $sender")
        Log.d(TAG, "Body: $body")
        
        val parser = NotificationParser(context)
        
        val isTransaction = parser.isTransactionMessage(sender, body)
        Log.d(TAG, "isTransactionMessage: $isTransaction")
        
        if (isTransaction) {
            Log.d(TAG, "✓ SMS identified as transaction, parsing...")
            val transaction = parser.parseTransaction(sender, body)
            
            if (transaction != null) {
                Log.d(TAG, "✓ Transaction parsed successfully")
                Log.d(TAG, "   Type: ${transaction.type}")
                Log.d(TAG, "   Amount: ${transaction.amount}")
                Log.d(TAG, "   Merchant: ${transaction.merchant}")
                parser.handleTransaction(transaction)
            } else {
                Log.e(TAG, "✗ parseTransaction returned null!")
            }
        } else {
            Log.d(TAG, "✗ Not identified as transaction SMS")
        }
    }
}
