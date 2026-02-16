package com.example.expense_tracker

import android.content.Context
import android.content.Intent
import android.util.Log
import android.app.NotificationManager
import android.app.NotificationChannel
import android.app.PendingIntent
import android.os.Build
import androidx.core.app.NotificationCompat
class NotificationParser(private val context: Context) {

    companion object {
        private const val TAG = "NotificationParser"
    }

    fun isTransactionMessage(sender: String, body: String): Boolean {
        val hasAccount = body.contains("A/c", ignoreCase = true) || 
                        body.contains("A/C", ignoreCase = true) ||
                        body.contains("account", ignoreCase = true)||
                        body.contains("Acct", ignoreCase = true) ||      
                    body.contains("card", ignoreCase = true) 
        
        val hasTransactionType = body.contains("debited", ignoreCase = true) || 
                                body.contains("credited", ignoreCase = true)
        
        val isOtp = body.contains("OTP", ignoreCase = true) || 
                    body.contains("verification", ignoreCase = true) ||
                    (body.length < 100 && body.matches(Regex(".*\\b\\d{4,6}\\b.*")))
        
        return hasAccount && hasTransactionType && !isOtp
    }

    fun parseTransaction(sender: String, body: String): NotificationListener.Transaction? {
    try {
        Log.d(TAG, "📝 Parsing transaction from: $sender")
        Log.d(TAG, "📝 Body: $body")
        
        // Extract account number FIRST
        val accountPattern = Regex(
    """(?:A/c|A/C|Acct|account|card|a/c no)\s*(?:no\.?|number)?\s*[Xx*]*([0-9]{4})""",
    RegexOption.IGNORE_CASE
)
        val accountMatch = accountPattern.find(body)
        val account = accountMatch?.groupValues?.get(1) ?: "****"
        
        // Context-aware type detection
        val accountIndex = accountMatch?.range?.first ?: -1
        val debitedIndex = body.indexOf("debited", ignoreCase = true)
        val creditedIndex = body.indexOf("credited", ignoreCase = true)
        
        Log.d(TAG, "📍 accountIndex: $accountIndex, debitedIndex: $debitedIndex, creditedIndex: $creditedIndex")
        
        val type = when {
            // If "debited" appears before or near account mention
            debitedIndex >= 0 && (accountIndex < 0 || debitedIndex <= accountIndex + 50) -> {
                Log.d(TAG, "✓ Detected as DEBIT (debited near account)")
                "DEBIT"
            }
            // If "credited" appears before or near account mention
            creditedIndex >= 0 && (accountIndex < 0 || creditedIndex <= accountIndex + 50) -> {
                Log.d(TAG, "✓ Detected as CREDIT (credited near account)")
                "CREDIT"
            }
            // Fallback checks
            body.contains("spent", ignoreCase = true) || 
            body.contains("paid", ignoreCase = true) ||
            body.contains("withdrawn", ignoreCase = true) -> {
                Log.d(TAG, "✓ Detected as DEBIT (fallback keywords)")
                "DEBIT"
            }
            body.contains("received", ignoreCase = true) ||
            body.contains("deposited", ignoreCase = true) -> {
                Log.d(TAG, "✓ Detected as CREDIT (fallback keywords)")
                "CREDIT"
            }
            else -> {
                Log.w(TAG, "⚠ Could not determine type, marking as UNKNOWN")
                "UNKNOWN"
            }
        }
        
        Log.d(TAG, "Transaction Type: $type")
        
        // Extract amount
        val amount = extractAmount(body)
        if (amount == null) {
            Log.e(TAG, "✗ Failed to extract amount")
            return null
        }
        Log.d(TAG, "Amount extracted: $amount")
        
        // Extract merchant/beneficiary
        val merchant = extractMerchant(body)
        Log.d(TAG, "Merchant extracted: $merchant")
        
        // Extract balance
        val balance = extractBalance(body)
        
        // Determine bank from sender
        val bank = determineBankFromSender(sender)
        
        return NotificationListener.Transaction(
            type = type,
            amount = amount,
            bank = bank,
            account = account,
            merchant = merchant,
            balance = balance
        )
        
    } catch (e: Exception) {
        Log.e(TAG, "❌ Error parsing transaction: ${e.message}")
        e.printStackTrace()
        return null
    }
}


    fun handleTransaction(transaction: NotificationListener.Transaction) {
        Log.d(TAG, "✓✓✓ TRANSACTION DETECTED ✓✓✓")
        Log.d(TAG, "Type: ${transaction.type}")
        Log.d(TAG, "Amount: ₹${transaction.amount}")
        Log.d(TAG, "Bank: ${transaction.bank}")
        Log.d(TAG, "Merchant: ${transaction.merchant}")
        
        // Check for duplicate within 10 seconds
        if (isDuplicateTransaction(transaction)) {
            Log.d(TAG, "Duplicate transaction detected, skipping")
            return
        }
        
        val savedCategory = getSavedCategory(transaction.merchant)
        
        if (savedCategory != null) {
            Log.d(TAG, "✨ Auto-categorized as: $savedCategory")
            sendToFlutter(transaction, savedCategory)
        } else {
            Log.d(TAG, "📋 Showing category popup for new merchant")
            showCategorizationPopup(transaction)
            sendToFlutter(transaction, "Uncategorized")
        }
    }

    private fun isDuplicateTransaction(transaction: NotificationListener.Transaction): Boolean {
        val prefs = context.getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
        val existingJson = prefs.getString("transactions", "[]")
        val transactionsArray = org.json.JSONArray(existingJson)
        
        // Check if transaction with same amount and merchant exists within 10 seconds
        for (i in 0 until transactionsArray.length()) {
            val transactionObj = transactionsArray.getJSONObject(i)
            val existingTimestamp = transactionObj.getLong("timestamp")
            val timeDiff = Math.abs(transaction.timestamp - existingTimestamp)
            
            if (timeDiff < 10000 && // Within 10 seconds
                transactionObj.getString("amount") == transaction.amount &&
                transactionObj.getString("merchant") == transaction.merchant) {
                return true
            }
        }
        return false
    }

    private fun getSavedCategory(merchant: String): String? {
        try {
            val prefs = context.getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
            val merchantMap = prefs.getString("merchant_categories", "{}")
            val merchantObj = org.json.JSONObject(merchantMap ?: "{}")
            
            val normalizedMerchant = merchant.trim().lowercase()
            
            if (merchantObj.has(normalizedMerchant)) {
                return merchantObj.getString(normalizedMerchant)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting saved category: ${e.message}")
        }
        return null
    }

    private fun sendToFlutter(transaction: NotificationListener.Transaction, category: String) {
        try {
            saveTransactionLocally(transaction, category)
            
            val transactionMap = mapOf(
                "type" to transaction.type,
                "amount" to transaction.amount,
                "bank" to transaction.bank,
                "account" to transaction.account,
                "merchant" to transaction.merchant,
                "balance" to transaction.balance,
                "timestamp" to transaction.timestamp,
                "category" to category
            )
            
            MainActivity.eventSink?.success(transactionMap)
            Log.d(TAG, "Transaction sent to Flutter with category: $category")
        } catch (e: Exception) {
            Log.e(TAG, "Error sending transaction to Flutter: ${e.message}")
        }
    }

    private fun saveTransactionLocally(transaction: NotificationListener.Transaction, category: String) {
        if (transaction.type == "CREDIT") {
            Log.d(TAG, "Skipping CREDIT transaction - not tracking income")
            return
        }
        
        try {
            val prefs = context.getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("transactions", "[]")
            val transactionsArray = org.json.JSONArray(existingJson)
            
            val transactionObj = org.json.JSONObject().apply {
                put("id", transaction.timestamp.toString())
                put("type", transaction.type)
                put("amount", transaction.amount)
                put("bank", transaction.bank)
                put("account", transaction.account)
                put("merchant", transaction.merchant)
                put("balance", transaction.balance)
                put("timestamp", transaction.timestamp)
                put("category", category)
            }
            
            transactionsArray.put(transactionObj)
            prefs.edit().putString("transactions", transactionsArray.toString()).apply()
            Log.d(TAG, "Transaction saved locally with category: $category")
        } catch (e: Exception) {
            Log.e(TAG, "Error saving transaction locally: ${e.message}")
        }
    }

    private fun showCategorizationPopup(transaction: NotificationListener.Transaction) {
    Log.d(TAG, "🚀 Attempting to launch popup...")
    
    // Check if we can launch activities from background
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        // Android 10+: Use notification-based approach
        Log.d(TAG, "📢 Android 10+ detected, using notification approach")
        showCategorizationNotification(transaction)
        return
    }
    
    // Android 9 and below: Try direct launch
    val intent = Intent(context, CategorySelectionActivity::class.java).apply {
        putExtra("transaction_id", "${transaction.timestamp}")
        putExtra("amount", transaction.amount)
        putExtra("merchant", transaction.merchant)
        putExtra("type", transaction.type)
        putExtra("bank", transaction.bank)
        putExtra("account", transaction.account)
        putExtra("balance", transaction.balance)
        putExtra("timestamp", transaction.timestamp)
        flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
    }
    
    try {
        context.startActivity(intent)
        Log.d(TAG, "✅ Popup activity started successfully")
    } catch (e: Exception) {
        Log.e(TAG, "❌ Failed to start popup: ${e.message}")
        e.printStackTrace()
        showCategorizationNotification(transaction)
    }
}

private fun showCategorizationNotification(transaction: NotificationListener.Transaction) {
    try {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        
        // Create notification channel (Android 8+)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "category_selection",
                "Expense Categorization",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Tap to categorize your expenses"
                setShowBadge(true)
                enableVibration(true)
                enableLights(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
        
        // Create intent for the activity
        val intent = Intent(context, CategorySelectionActivity::class.java).apply {
            putExtra("transaction_id", "${transaction.timestamp}")
            putExtra("amount", transaction.amount)
            putExtra("merchant", transaction.merchant)
            putExtra("type", transaction.type)
            putExtra("bank", transaction.bank)
            putExtra("account", transaction.account)
            putExtra("balance", transaction.balance)
            putExtra("timestamp", transaction.timestamp)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        
        val pendingIntent = PendingIntent.getActivity(
            context,
            transaction.timestamp.toInt(),
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        // Build notification
        val notification = NotificationCompat.Builder(context, "category_selection")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle("💰 Categorize ₹${transaction.amount}")
            .setContentText("Tap to assign category for ${transaction.merchant}")
            .setStyle(NotificationCompat.BigTextStyle()
                .bigText("Expense of ₹${transaction.amount} to ${transaction.merchant}. Tap to categorize."))
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setDefaults(NotificationCompat.DEFAULT_ALL)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .build()
        
        notificationManager.notify(transaction.timestamp.toInt(), notification)
        Log.d(TAG, "✅ Categorization notification shown successfully")
    } catch (e: Exception) {
        Log.e(TAG, "❌ Failed to show notification: ${e.message}")
        e.printStackTrace()
    }
}


    private fun extractAmount(text: String): String? {
        val patterns = listOf(
            "(?:INR|Rs\\.?|₹)\\s*([0-9,]+(?:\\.[0-9]{1,2})?)",
            "(?:debited|credited|paid|received|withdrawn|deposited)\\s+(?:with\\s+)?(?:INR|Rs\\.?|₹)?\\s*([0-9,]+(?:\\.[0-9]{1,2})?)",
            "(?:amount|amt)\\s*(?:of)?\\s*(?:INR|Rs\\.?|₹)?\\s*([0-9,]+(?:\\.[0-9]{1,2})?)"
        )
        
        for (pattern in patterns) {
            val regex = Regex(pattern, RegexOption.IGNORE_CASE)
            val match = regex.find(text)
            if (match != null && match.groupValues.size > 1) {
                val amount = match.groupValues[1].replace(",", "")
                val numAmount = amount.toDoubleOrNull()
                if (numAmount != null && numAmount > 0 && numAmount < 10000000) {
                    return amount
                }
            }
        }
        return null
    }

    private fun extractMerchant(text: String): String {
    Log.d(TAG, "🔍 Extracting merchant from: $text")
    
    // Pattern 1: "towards XXX."
    val towardsPattern = Regex("""towards\s+(.+?)\.""", RegexOption.IGNORE_CASE)
    towardsPattern.find(text)?.let { match ->
        val merchant = match.groupValues[1].trim()
        Log.d(TAG, "✓ Merchant found (towards): $merchant")
        return merchant
    }
    
    // Pattern 2: "to/at XXX on/via/."
    val toPattern = Regex("""(?:to|at)\s+([A-Z][A-Za-z\s&.'-]{3,40})(?:\s+on|\s+via|\.|,)""", RegexOption.IGNORE_CASE)
    toPattern.find(text)?.let { match ->
        val merchant = match.groupValues[1].trim()
        Log.d(TAG, "✓ Merchant found (to/at): $merchant")
        return merchant
    }
    
    // Pattern 3: "XXX credited" (for P2P transfers like yours)
    val creditedToPattern = Regex(""";\s*([A-Z][A-Za-z\s]{2,30})\s+credited""", RegexOption.IGNORE_CASE)
    creditedToPattern.find(text)?.let { match ->
        val merchant = match.groupValues[1].trim()
        Log.d(TAG, "✓ Merchant found (credited to): $merchant")
        return merchant
    }
    
    // Pattern 4: "debited to XXX" or "paid to XXX"
    val debitedToPattern = Regex("""(?:debited|paid)\s+(?:to|for)\s+([A-Z][A-Za-z\s]{2,30})(?:\s|;|\.)""", RegexOption.IGNORE_CASE)
    debitedToPattern.find(text)?.let { match ->
        val merchant = match.groupValues[1].trim()
        Log.d(TAG, "✓ Merchant found (debited/paid to): $merchant")
        return merchant
    }
    
    // Pattern 5: "VPA/UPI/UPI ID XXX"
    val vpaPattern = Regex("""(?:VPA|UPI|UPI ID)\s*[:;]?\s*([A-Za-z0-9@.-]+)""", RegexOption.IGNORE_CASE)
    vpaPattern.find(text)?.let { match ->
        val merchant = match.groupValues[1].trim()
        Log.d(TAG, "✓ Merchant found (VPA): $merchant")
        return merchant
    }
    
    Log.w(TAG, "⚠ No merchant pattern matched, returning Unknown")
    return "Unknown"
}

    private fun extractBalance(text: String): String {
        val balancePattern = Regex(
            "(?:balance|bal|avbl bal|available balance|avl bal|avail bal)(?:\\s+is)?\\s*(?:INR|Rs\\.?|₹)?\\s*([0-9,]+(?:\\.[0-9]{1,2})?)", 
            RegexOption.IGNORE_CASE
        )
        return balancePattern.find(text)?.groupValues?.get(1)?.replace(",", "") ?: "N/A"
    }

    private fun determineBankFromSender(sender: String): String {
        return when {
            sender.contains("HDFC", ignoreCase = true) -> "HDFC Bank"
            sender.contains("ICICI", ignoreCase = true) -> "ICICI Bank"
            sender.contains("SBI", ignoreCase = true) -> "State Bank of India"
            sender.contains("AXIS", ignoreCase = true) -> "Axis Bank"
            sender.contains("KOTAK", ignoreCase = true) -> "Kotak Bank"
            sender.contains("YES", ignoreCase = true) -> "Yes Bank"
            sender.contains("INDUS", ignoreCase = true) -> "IndusInd Bank"
            sender.contains("PAYTM", ignoreCase = true) -> "Paytm"
            sender.contains("PHONEPE", ignoreCase = true) -> "PhonePe"
            sender.contains("GPAY", ignoreCase = true) -> "Google Pay"
            sender.contains("AMAZON", ignoreCase = true) -> "Amazon Pay"
            sender.contains("PNB", ignoreCase = true) -> "Punjab National Bank"
            sender.contains("CANARA", ignoreCase = true) -> "Canara Bank"
            sender.contains("BOB", ignoreCase = true) -> "Bank of Baroda"
            sender.contains("UNION", ignoreCase = true) -> "Union Bank"
            else -> sender
        }
    }
}