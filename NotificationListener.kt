package com.example.expense_tracker

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import org.json.JSONObject
import org.json.JSONArray
import java.util.Calendar

class NotificationListener : NotificationListenerService() {

    companion object {
        private const val TAG = "NotificationListener"
        private const val CATEGORY_CHANNEL_ID = "category_selection"
        private var notificationId = 1000

        // SMS/Messaging app packages
        private val SMS_PACKAGES = listOf(
            "com.samsung.android.messaging",
            "com.google.android.apps.messaging",
            "com.android.messaging",
            "com.google.android.gm",
        )
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        super.onNotificationPosted(sbn)

        val packageName = sbn.packageName

        // Only process messaging app notifications
        if (SMS_PACKAGES.contains(packageName)) {
            Log.d(TAG, "=== SMS Notification Received ===")
            Log.d(TAG, "Package: $packageName")
            handleSmsNotification(sbn)
        }
    }

    private fun handleSmsNotification(sbn: StatusBarNotification) {
        try {
            val notification = sbn.notification
            val extras = notification.extras

            // Extract with proper UTF-8 handling
            val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
            val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
            val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString() ?: ""
            val subText = extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString() ?: ""

            // Clean strings with UTF-8 encoding
            val sender = cleanUTF8String(title.ifEmpty { subText })
            val messageBody = cleanUTF8String(bigText.ifEmpty { text })

            Log.d(TAG, "Sender: $sender")
            Log.d(TAG, "Message: $messageBody")

            // Check if it's a transaction message
            if (isTransactionMessage(sender, messageBody)) {
                val transaction = parseTransaction(sender, messageBody)
                if (transaction != null) {
                    // Check for saved category
                    val savedCategory = getSavedCategoryForMerchant(transaction.merchant)
                    if (savedCategory != null) {
                        // Auto-categorize with saved category
                        sendTransactionToFlutter(transaction, savedCategory)
                    } else {
                        // Show popup for new merchant
                        showCategorizationPopup(transaction)
                        // Also send to Flutter as uncategorized
                        sendTransactionToFlutter(transaction, "Uncategorized")
                    }
                }
            }

        } catch (e: Exception) {
            Log.e(TAG, "Error processing SMS notification: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun cleanUTF8String(input: String): String {
        return try {
            String(input.toByteArray(Charsets.UTF_8), Charsets.UTF_8)
        } catch (e: Exception) {
            input
        }
    }

    private fun sanitizeMerchantName(merchant: String): String {
        // First, ensure proper UTF-8 encoding
        val cleanString = try {
            String(merchant.toByteArray(Charsets.UTF_8), Charsets.UTF_8)
        } catch (e: Exception) {
            merchant
        }

        return cleanString
            .replace(Regex("[^\\p{L}\\p{N}\\s&.'-]"), "") // Keep letters, numbers, spaces, &, ., ', -
            .replace(Regex("\\s+"), " ") // Replace multiple spaces with single space
            .trim()
            .take(50) // Limit length to 50 characters
    }

    private fun extractMessagesFromNotification(extras: android.os.Bundle): List<String> {
        val messages = mutableListOf<String>()

        try {
            // Try to extract from EXTRA_MESSAGES (for messaging style notifications)
            val messagesArray = extras.getParcelableArray(Notification.EXTRA_MESSAGES)
            if (messagesArray != null) {
                for (item in messagesArray) {
                    if (item is android.os.Bundle) {
                        val text = item.getCharSequence("text")?.toString()
                        if (text != null && text.isNotEmpty()) {
                            messages.add(text)
                        }
                    }
                }
            }

            // Try EXTRA_MESSAGE_LINES for inbox style
            val lines = extras.getCharSequenceArray(Notification.EXTRA_TEXT_LINES)
            if (lines != null) {
                for (line in lines) {
                    if (line != null && line.toString().isNotEmpty()) {
                        messages.add(line.toString())
                    }
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error extracting messages: ${e.message}")
        }

        return messages
    }

    private fun getSavedCategoryForMerchant(merchant: String): String? {
        try {
            val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
            val merchantMap = prefs.getString("merchant_categories", "{}")
            val merchantObj = JSONObject(merchantMap ?: "{}")

            // Normalize merchant name for matching (lowercase, trim)
            val normalizedMerchant = merchant.trim().lowercase()

            if (merchantObj.has(normalizedMerchant)) {
                val category = merchantObj.getString(normalizedMerchant)
                Log.d(TAG, "Found saved category '$category' for merchant '$merchant'")
                return category
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error getting saved category: ${e.message}")
        }
        return null
    }

    private fun isTransactionMessage(sender: String, body: String): Boolean {
        // 1. Must have "A/c" or "A/C"
        val hasAccount = body.contains("A/c", ignoreCase = true) || 
                        body.contains("A/C", ignoreCase = true) ||
                        body.contains("account", ignoreCase = true)

        // 2. Must have "debited" or "credited"
        val hasTransactionType = body.contains("debited", ignoreCase = true) || 
                                body.contains("credited", ignoreCase = true)

        // 3. Filter out OTPs (short messages with just numbers)
        val isOtp = body.contains("OTP", ignoreCase = true) || 
                    body.contains("verification", ignoreCase = true) ||
                    (body.length < 100 && body.matches(Regex(".*\\b\\d{4,6}\\b.*")))

        val isTransaction = hasAccount && hasTransactionType && !isOtp

        if (isTransaction) {
            Log.d(TAG, "✓ Transaction detected: hasAccount=$hasAccount, hasTransactionType=$hasTransactionType")
        } else {
            Log.d(TAG, "✗ Not a transaction: hasAccount=$hasAccount, hasTransactionType=$hasTransactionType, isOtp=$isOtp")
        }

        return isTransaction
    }

    data class Transaction(
        val type: String,
        val amount: String,
        val bank: String,
        val account: String,
        val merchant: String,
        val balance: String,
        val timestamp: Long = System.currentTimeMillis()
    )

    fun parseTransaction(sender: String, body: String): Transaction? {
        try {
            // Extract account number FIRST
            val accountPattern = Regex("""(?:A/c|A/C|account|card|a/c no)\s*(?:no\.?|number)?\s*[Xx*]*([0-9]{4})""", RegexOption.IGNORE_CASE)
            val accountMatch = accountPattern.find(body)
            val account = accountMatch?.groupValues?.get(1) ?: "****"

            // Context-aware type detection
            val accountIndex = accountMatch?.range?.first ?: 0
            val debitedIndex = body.indexOf("debited", ignoreCase = true)
            val creditedIndex = body.indexOf("credited", ignoreCase = true)

            val type = when {
                debitedIndex in 0..accountIndex + 50 -> "DEBIT"
                creditedIndex in 0..accountIndex + 50 -> "CREDIT"
                body.contains("spent", ignoreCase = true) -> "DEBIT"
                body.contains("received", ignoreCase = true) -> "CREDIT"
                else -> "UNKNOWN"
            }

            // Extract amount
            val amount = extractAmount(body) ?: return null

            // Extract merchant/beneficiary
            val merchant = extractMerchant(body)
            val balance = extractBalance(body)
            val bank = determineBankFromSender(sender)

            return Transaction(
                type = type,
                amount = amount,
                bank = bank,
                account = account,
                merchant = merchant,
                balance = balance
            )

        } catch (e: Exception) {
            Log.e(TAG, "Error parsing transaction: ${e.message}")
            return null
        }
    }

    private fun extractAmount(text: String): String? {
        // Patterns to match Indian currency
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
                // Validate amount is reasonable (not year, not ID)
                if (numAmount != null && numAmount > 0 && numAmount < 10000000) {
                    return amount
                }
            }
        }
        return null
    }

    private fun extractMerchant(text: String): String {
        // Extract text between "towards" and "." (full stop)
        val towardsPattern = Regex("towards\\s+(.+?)\\.", RegexOption.IGNORE_CASE)
        towardsPattern.find(text)?.let { match ->
            return sanitizeMerchantName(match.groupValues[1])
        }

        // Alternative: "to" pattern - improved to avoid special chars
        val toPattern = Regex("(?:to|at)\\s+([A-Za-z0-9][A-Za-z0-9\\s&.'-]{2,40}?)(?:\\s+on|\\s+via|\\.|,|\\s+for)", RegexOption.IGNORE_CASE)
        toPattern.find(text)?.let { match ->
            return sanitizeMerchantName(match.groupValues[1])
        }

        // VPA/UPI pattern
        val vpaPattern = Regex("(?:VPA|UPI|UPI ID)\\s+([A-Za-z0-9@.-]+)", RegexOption.IGNORE_CASE)
        vpaPattern.find(text)?.let { match ->
            return sanitizeMerchantName(match.groupValues[1])
        }

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

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        super.onNotificationRemoved(sbn)
    }

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification Listener Service Connected!")
        Log.d(TAG, "Monitoring SMS notifications from messaging apps")
        createNotificationChannel()
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification Listener Service Disconnected!")
    }

    private fun sendTransactionToFlutter(transaction: Transaction, category: String = "Uncategorized") {
        try {
            // Save to SharedPreferences first
            saveTransactionLocally(transaction, category)

            // Then try to send to Flutter
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
        checkCategoryCapAndNotify(category)
    }

    private fun saveTransactionLocally(transaction: Transaction, category: String = "Uncategorized") {
        if (transaction.type == "CREDIT") {
            Log.d(TAG, "Skipping CREDIT transaction - not tracking income")
            return
        }

        try {
            val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("transactions", "[]")
            val transactionsArray = JSONArray(existingJson)

            // Create transaction object
            val transactionObj = JSONObject().apply {
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

    private fun checkCategoryCapAndNotify(category: String) {
        val sharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val categoryCapsJson = sharedPreferences.getString("flutter.category_caps", null) ?: return

        try {
            val categoryCaps = JSONObject(categoryCapsJson)
            if (!categoryCaps.has(category)) return

            val capConfig = categoryCaps.getJSONObject(category)
            val capType = capConfig.getString("type")
            val capValue = capConfig.getDouble("value")

            val userDataJson = sharedPreferences.getString("flutter.user_data", null) ?: return
            val userData = JSONObject(userDataJson)
            val monthlyIncome = userData.getDouble("monthly_income")

            val capAmount = if (capType == "percentage") {
                monthlyIncome * capValue / 100
            } else {
                capValue
            }

            val currentMonthSpending = getCurrentMonthSpending(category)
            val percentageUsed = (currentMonthSpending / capAmount * 100)

            if (percentageUsed >= 80 && percentageUsed < 100) {
                sendCapWarningNotification(category, currentMonthSpending, capAmount, percentageUsed, "warning")
            } else if (percentageUsed >= 100) {
                sendCapWarningNotification(category, currentMonthSpending, capAmount, percentageUsed, "exceeded")
            }
        } catch (e: Exception) {
            Log.e("NotificationListener", "Error checking category cap: ${e.message}")
        }
    }

    private fun getCurrentMonthSpending(category: String): Double {
        val sharedPreferences = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val transactionsJson = sharedPreferences.getString("flutter.saved_transactions", "[]") ?: "[]"

        try {
            val transactions = JSONArray(transactionsJson)
            val calendar = Calendar.getInstance()
            val currentMonth = calendar.get(Calendar.MONTH)
            val currentYear = calendar.get(Calendar.YEAR)

            var totalSpending = 0.0

            for (i in 0 until transactions.length()) {
                val transaction = transactions.getJSONObject(i)
                if (transaction.getString("category") == category && 
                    transaction.getString("type") == "DEBIT") {

                    val timestamp = transaction.getLong("timestamp")
                    calendar.timeInMillis = timestamp

                    if (calendar.get(Calendar.MONTH) == currentMonth && 
                        calendar.get(Calendar.YEAR) == currentYear) {
                        totalSpending += transaction.getDouble("amount")
                    }
                }
            }

            return totalSpending
        } catch (e: Exception) {
            return 0.0
        }
    }

    private fun sendCapWarningNotification(
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
                enableVibration(true)
                vibrationPattern = longArrayOf(0, 500, 200, 500)
            }
            notificationManager.createNotificationChannel(channel)
        }

        val (title, message) = when (type) {
            "warning" -> Pair(
                "⚠️ Spending Alert: $category",
                "You've used ${percentage.toInt()}% of your $category budget"
            )
            else -> Pair(
                "🚨 Budget Exceeded: $category",
                "You've exceeded your cap by ₹${(currentSpending - capAmount).toInt()}"
            )
        }

        val notification = NotificationCompat.Builder(this, "spending_caps")
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setAutoCancel(true)
            .build()

        notificationManager.notify("cap_$category".hashCode(), notification)
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val name = "Category Selection"
            val descriptionText = "Notifications for categorizing expenses"
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CATEGORY_CHANNEL_ID, name, importance).apply {
                description = descriptionText
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showCategorizationPopup(transaction: Transaction) {
        // Launch category selection activity as a popup
        Log.d(TAG, "🚀 Attempting to launch popup...")
        val intent = Intent(this, CategorySelectionActivity::class.java).apply {
            putExtra("transaction_id", "${transaction.timestamp}")
            putExtra("amount", transaction.amount)
            putExtra("merchant", transaction.merchant)
            putExtra("type", transaction.type)
            putExtra("bank", transaction.bank)
            putExtra("account", transaction.account)
            putExtra("balance", transaction.balance)
            putExtra("timestamp", transaction.timestamp)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
        }

        startActivity(intent)
        Log.d(TAG, "Category selection popup launched")
    }
}