package com.example.expense_tracker

import android.app.Activity
import android.content.Context
import android.os.Bundle
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.ScrollView
import android.graphics.Color
import android.view.Gravity
import android.view.WindowManager
import android.util.Log
import android.graphics.drawable.GradientDrawable
import android.graphics.drawable.StateListDrawable

class CategorySelectionActivity : Activity() {
    
    private val categories = listOf(
        "Food", "Groceries", "Shopping", "Clothes", "Laundry",
        "Transport", "Entertainment", "Bills", "Health", "Others"
    )
    
    private var transactionId = ""
    private var amount = 0.0
    private var merchant = ""
    private var type = ""
    private var bank = ""
    private var account = ""
    private var balance = ""
    private var timestamp = 0L
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("CategoryActivity", "Activity created!")
        
        // Make fullscreen
        window.setLayout(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT
        )
        
        // Get transaction details
        transactionId = intent.getStringExtra("transaction_id") ?: ""
        amount = intent.getStringExtra("amount")?.toDoubleOrNull() ?: 0.0
        merchant = intent.getStringExtra("merchant") ?: "Unknown"
        type = intent.getStringExtra("type") ?: "DEBIT"
        bank = intent.getStringExtra("bank") ?: ""
        account = intent.getStringExtra("account") ?: ""
        balance = intent.getStringExtra("balance") ?: ""
        timestamp = intent.getLongExtra("timestamp", System.currentTimeMillis())
        
        Log.d("CategoryActivity", "Amount: $amount, Merchant: $merchant")
        
        // Create semi-transparent background
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#CC000000"))
            gravity = Gravity.CENTER
            setPadding(40, 40, 40, 40)
            setOnClickListener {
                // Dismiss on background tap with "Others" as default
                selectCategory("Others")
            }
        }
        
        // Create content card
        val contentCard = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.WHITE)
            
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 100, 0, 100)
            }
            layoutParams = params
            
            // Rounded corners
            val shape = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 24f
                setColor(Color.WHITE)
            }
            background = shape
            
            // Prevent clicks from going through to background
            setOnClickListener { }
        }
        
        // Transaction Info Section
        val infoSection = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(32, 32, 32, 24)
            gravity = Gravity.CENTER
        }
        
        // Amount
        val amountText = TextView(this).apply {
            text = "₹${String.format("%.2f", amount)}"
            textSize = 32f
            setTextColor(Color.parseColor("#F44336"))
            gravity = Gravity.CENTER
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        infoSection.addView(amountText)
        
        // Merchant
        val merchantText = TextView(this).apply {
            text = merchant
            textSize = 15f
            setTextColor(Color.parseColor("#424242"))
            setPadding(20, 8, 20, 4)
            gravity = Gravity.CENTER
            maxLines = 2
        }
        infoSection.addView(merchantText)
        
        // Bank info
        val bankInfo = TextView(this).apply {
            text = "$bank •• $account"
            textSize = 13f
            setTextColor(Color.parseColor("#757575"))
            gravity = Gravity.CENTER
        }
        infoSection.addView(bankInfo)
        
        contentCard.addView(infoSection)
        
        // Divider
        val divider = android.view.View(this).apply {
            setBackgroundColor(Color.parseColor("#E0E0E0"))
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                1
            )
        }
        contentCard.addView(divider)
        
        // Category header
        val categoryHeader = TextView(this).apply {
            text = "Select Category"
            textSize = 14f
            setTextColor(Color.parseColor("#757575"))
            setPadding(32, 16, 32, 12)
            setTypeface(null, android.graphics.Typeface.BOLD)
        }
        contentCard.addView(categoryHeader)
        
        // Scrollable category list
        val scrollView = ScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                // Max height for scrolling
                height = (resources.displayMetrics.heightPixels * 0.4).toInt()
            }
            isVerticalScrollBarEnabled = false
        }
        
        val categoryContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(16, 0, 16, 16)
        }
        
        // Create category items
        categories.forEach { category ->
            val categoryItem = createCategoryItem(category)
            categoryContainer.addView(categoryItem)
        }
        
        scrollView.addView(categoryContainer)
        contentCard.addView(scrollView)
        
        mainLayout.addView(contentCard)
        setContentView(mainLayout)
    }
    
    private fun createCategoryItem(category: String): LinearLayout {
        return LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER_VERTICAL
            setPadding(16, 12, 16, 12)
            
            val params = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 4, 0, 4)
            }
            layoutParams = params
            
            // Rounded background
            val normalShape = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 12f
                setColor(Color.WHITE)
            }
            
            val pressedShape = GradientDrawable().apply {
                shape = GradientDrawable.RECTANGLE
                cornerRadius = 12f
                setColor(Color.parseColor("#F5F5F5"))
            }
            
            val stateListDrawable = StateListDrawable().apply {
                addState(intArrayOf(android.R.attr.state_pressed), pressedShape)
                addState(intArrayOf(), normalShape)
            }
            
            background = stateListDrawable
            
            // Make it clickable
            isClickable = true
            isFocusable = true
            
            // Color indicator circle
            val colorCircle = android.view.View(this.context).apply {
                val circleParams = LinearLayout.LayoutParams(36, 36).apply {
                    setMargins(0, 0, 16, 0)
                }
                layoutParams = circleParams
                
                val circleShape = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(getCategoryColor(category))
                }
                background = circleShape
            }
            addView(colorCircle)
            
            // Category icon (emoji representation)
            val iconText = TextView(this.context).apply {
                text = getCategoryIcon(category)
                textSize = 20f
                gravity = Gravity.CENTER
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(0, 0, 16, 0)
                }
            }
            addView(iconText)
            
            // Category name
            val categoryName = TextView(this.context).apply {
                text = category
                textSize = 16f
                setTextColor(Color.parseColor("#212121"))
                setTypeface(null, android.graphics.Typeface.NORMAL)
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.WRAP_CONTENT,
                    1f
                )
            }
            addView(categoryName)
            
            // Click listener
            setOnClickListener {
                selectCategory(category)
            }
        }
    }
    
    private fun getCategoryColor(category: String): Int {
        return when (category) {
            "Food" -> Color.parseColor("#FF9800")
            "Groceries" -> Color.parseColor("#4CAF50")
            "Shopping" -> Color.parseColor("#9C27B0")
            "Clothes" -> Color.parseColor("#E91E63")
            "Laundry" -> Color.parseColor("#2196F3")
            "Transport" -> Color.parseColor("#009688")
            "Entertainment" -> Color.parseColor("#F44336")
            "Bills" -> Color.parseColor("#795548")
            "Health" -> Color.parseColor("#00BCD4")
            else -> Color.parseColor("#9E9E9E")
        }
    }
    
    private fun getCategoryIcon(category: String): String {
        return when (category) {
            "Food" -> "🍔"
            "Groceries" -> "🛒"
            "Shopping" -> "🛍️"
            "Clothes" -> "👕"
            "Laundry" -> "🧺"
            "Transport" -> "🚗"
            "Entertainment" -> "🎬"
            "Bills" -> "📄"
            "Health" -> "⚕️"
            else -> "📌"
        }
    }

    private fun updateTransactionCategory(transactionId: String, category: String) {
        try {
            val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
            val existingJson = prefs.getString("transactions", "[]")
            val transactionsArray = org.json.JSONArray(existingJson)
            
            // Find and update the transaction
            for (i in 0 until transactionsArray.length()) {
                val transactionObj = transactionsArray.getJSONObject(i)
                if (transactionObj.getString("id") == transactionId) {
                    transactionObj.put("category", category)
                    break
                }
            }
            
            prefs.edit().putString("transactions", transactionsArray.toString()).apply()
            Log.d("CategoryActivity", "Category updated in storage")
        } catch (e: Exception) {
            Log.e("CategoryActivity", "Error updating category: ${e.message}")
        }
    }
    private fun selectCategory(category: String) {
    // Save merchant-category mapping for future auto-categorization
    saveMerchantCategory(merchant, category)
    
    // Update transaction in SharedPreferences
    updateTransactionCategory(transactionId, category)
    
    // Send complete transaction with category to Flutter
    val transactionMap = mapOf(
        "id" to transactionId,
        "type" to type,
        "amount" to amount.toString(),
        "merchant" to merchant,
        "account" to account,
        "bank" to bank,
        "balance" to balance,
        "timestamp" to timestamp,
        "category" to category,
        "isCategorized" to true
    )
    
    MainActivity.eventSink?.success(transactionMap)
    
    // Close activity
    finish()
}

private fun saveMerchantCategory(merchant: String, category: String) {
    try {
        val prefs = getSharedPreferences("expense_tracker", Context.MODE_PRIVATE)
        val merchantMap = prefs.getString("merchant_categories", "{}")
        val merchantObj = org.json.JSONObject(merchantMap ?: "{}")
        
        // Normalize merchant name (lowercase, trim)
        val normalizedMerchant = merchant.trim().lowercase()
        
        // Save the mapping
        merchantObj.put(normalizedMerchant, category)
        
        prefs.edit().putString("merchant_categories", merchantObj.toString()).apply()
        Log.d("CategoryActivity", "Saved: '$merchant' → '$category'")
    } catch (e: Exception) {
        Log.e("CategoryActivity", "Error saving merchant category: ${e.message}")
    }
}
    
    override fun onBackPressed() {
        // Allow back button to dismiss with "Others" as default
        selectCategory("Others")
    }
}