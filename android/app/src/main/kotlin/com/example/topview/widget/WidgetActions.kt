package com.example.topview.widget

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.glance.GlanceId
import androidx.glance.action.ActionParameters
import androidx.glance.appwidget.action.ActionCallback

/**
 * Action callback for refreshing widget data
 * 
 * This callback is triggered when the user taps the refresh button on the widget.
 * It opens the app with a refresh flag, which triggers data fetching and widget update.
 * This is more reliable than background intents which require the app to be running.
 */
class RefreshCallback : ActionCallback {
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        try {
            // Open the app with a refresh flag - this is more reliable than background intents
            val intent = Intent().apply {
                action = Intent.ACTION_MAIN
                addCategory(Intent.CATEGORY_LAUNCHER)
                setClassName("com.example.topview", "com.example.topview.MainActivity")
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
                // Pass refresh action via data URI
                data = Uri.parse("topview://widget_refresh")
            }
            context.startActivity(intent)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}

/**
 * Action callback for opening the app to a specific page
 */
class OpenAppCallback : ActionCallback {
    companion object {
        val TARGET_KEY = ActionParameters.Key<String>("target")
    }
    
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val target = parameters[TARGET_KEY] ?: "home"
        
        // Create intent to open main activity
        val intent = Intent().apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            setClassName("com.example.topview", "com.example.topview.MainActivity")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            
            // Pass the target for navigation
            data = Uri.parse("topview://open_app?target=$target")
        }
        
        context.startActivity(intent)
    }
}

/**
 * Action callback for opening a specific stock detail
 */
class OpenStockCallback : ActionCallback {
    companion object {
        val SYMBOL_KEY = ActionParameters.Key<String>("symbol")
    }
    
    override suspend fun onAction(
        context: Context,
        glanceId: GlanceId,
        parameters: ActionParameters
    ) {
        val symbol = parameters[SYMBOL_KEY] ?: return
        
        val intent = Intent().apply {
            action = Intent.ACTION_MAIN
            addCategory(Intent.CATEGORY_LAUNCHER)
            setClassName("com.example.topview", "com.example.topview.MainActivity")
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            data = Uri.parse("topview://open_stock?symbol=$symbol")
        }
        
        context.startActivity(intent)
    }
}
