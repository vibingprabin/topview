package com.example.topview.widget

import android.content.Context
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.provideContent
import androidx.glance.GlanceId
import androidx.glance.appwidget.SizeMode
import es.antonborri.home_widget.HomeWidgetGlanceState
import es.antonborri.home_widget.HomeWidgetGlanceStateDefinition
import androidx.compose.ui.unit.dp
import androidx.glance.LocalSize
import androidx.glance.currentState
import androidx.glance.state.GlanceStateDefinition

/**
 * Main widget provider for TopView NEPSE Portfolio Tracker
 * Supports three sizes: Small, Medium, and Large
 * 
 * Theme: Broker Intel - Dark navy (#2B2D42), Rich blue (#118AB2), Pink accent (#EF476F)
 */
class TopViewWidgetProvider : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = TopViewWidget()
}

class TopViewWidget : GlanceAppWidget() {
    
    // Support different widget sizes
    override val sizeMode = SizeMode.Exact
    
    override val stateDefinition: GlanceStateDefinition<*> = HomeWidgetGlanceStateDefinition()
    
    override suspend fun provideGlance(context: Context, id: GlanceId) {
        provideContent {
            val prefs = currentState<HomeWidgetGlanceState>().preferences
            
            // Read widget data from SharedPreferences (set by Flutter via home_widget)
            // Data from Flutter is stored as strings, so we parse them
            val nepseIndex = prefs.getString("nepse_index", "0.0")?.toDoubleOrNull() ?: 0.0
            val indexChange = prefs.getString("index_change", "0.0")?.toDoubleOrNull() ?: 0.0
            val indexChangePercent = prefs.getString("index_change_percent", "0.0")?.toDoubleOrNull() ?: 0.0
            val marketStatus = prefs.getString("market_status", "CLOSED") ?: "CLOSED"
            val portfolioValue = prefs.getString("portfolio_value", "0.0")?.toDoubleOrNull() ?: 0.0
            val portfolioChange = prefs.getString("portfolio_change", "0.0")?.toDoubleOrNull() ?: 0.0
            val portfolioChangePercent = prefs.getString("portfolio_change_percent", "0.0")?.toDoubleOrNull() ?: 0.0
            val topHoldings = prefs.getString("top_holdings", "[]") ?: "[]"
            val upcomingIpos = prefs.getString("upcoming_ipos", "[]") ?: "[]"
            val lastUpdate = prefs.getString("last_update", "") ?: ""
            
            // Determine which widget to show based on available size
            val size = LocalSize.current
            
            when {
                // Small widget: width < 200dp or height < 150dp
                size.width < 200.dp || size.height < 150.dp -> {
                    SmallWidgetContent(
                        nepseIndex = nepseIndex,
                        indexChange = indexChange,
                        indexChangePercent = indexChangePercent,
                        marketStatus = marketStatus
                    )
                }
                // Large widget: width > 300dp and height > 280dp
                size.width > 300.dp && size.height > 280.dp -> {
                    LargeWidgetContent(
                        nepseIndex = nepseIndex,
                        indexChange = indexChange,
                        indexChangePercent = indexChangePercent,
                        marketStatus = marketStatus,
                        portfolioValue = portfolioValue,
                        portfolioChange = portfolioChange,
                        portfolioChangePercent = portfolioChangePercent,
                        topHoldingsJson = topHoldings,
                        upcomingIposJson = upcomingIpos,
                        lastUpdate = lastUpdate
                    )
                }
                // Medium widget: everything else
                else -> {
                    MediumWidgetContent(
                        nepseIndex = nepseIndex,
                        indexChange = indexChange,
                        indexChangePercent = indexChangePercent,
                        marketStatus = marketStatus,
                        portfolioValue = portfolioValue,
                        portfolioChange = portfolioChange,
                        portfolioChangePercent = portfolioChangePercent
                    )
                }
            }
        }
    }
}
