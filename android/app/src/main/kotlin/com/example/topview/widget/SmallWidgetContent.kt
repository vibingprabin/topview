package com.example.topview.widget

import android.content.Intent
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceModifier
import androidx.glance.layout.*
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.glance.text.FontWeight
import androidx.glance.background
import androidx.glance.unit.ColorProvider
import androidx.glance.appwidget.cornerRadius
import androidx.glance.action.clickable
import androidx.glance.appwidget.action.actionStartActivity
import androidx.compose.ui.graphics.Color

private val DarkNavy = Color(0xFF2B2D42)
private val RichBlue = Color(0xFF118AB2)
private val PositiveGreen = Color(0xFF06D6A0)
private val NegativeRed = Color(0xFFEF476F)
private val TextPrimary = Color(0xFFFFFFFF)
private val TextSecondary = Color(0xFFB0B0B0)
private val StatusGreenBg = Color(0x3306D6A0)
private val StatusGrayBg = Color(0x33B0B0B0)

@Composable
fun SmallWidgetContent(
    nepseIndex: Double,
    indexChange: Double,
    indexChangePercent: Double,
    marketStatus: String
) {
    val isPositive = indexChange >= 0
    val changeColor = if (isPositive) PositiveGreen else NegativeRed
    val statusColor = if (marketStatus == "OPEN") PositiveGreen else TextSecondary
    val statusBgColor = if (marketStatus == "OPEN") StatusGreenBg else StatusGrayBg
    
    val openAppIntent = Intent().apply {
        action = Intent.ACTION_MAIN
        addCategory(Intent.CATEGORY_LAUNCHER)
        setClassName("com.example.topview", "com.example.topview.MainActivity")
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
    }
    
    Box(
        modifier = GlanceModifier
            .fillMaxSize()
            .background(DarkNavy)
            .cornerRadius(16.dp)
            .padding(12.dp)
            .clickable(actionStartActivity(openAppIntent))
    ) {
        Column(
            modifier = GlanceModifier.fillMaxSize(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "NEPSE",
                style = TextStyle(
                    color = ColorProvider(RichBlue),
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Medium
                )
            )
            
            Spacer(modifier = GlanceModifier.height(4.dp))
            
            Text(
                text = formatIndex(nepseIndex),
                style = TextStyle(
                    color = ColorProvider(TextPrimary),
                    fontSize = 22.sp,
                    fontWeight = FontWeight.Bold
                )
            )
            
            Spacer(modifier = GlanceModifier.height(4.dp))
            
            Text(
                text = formatChange(indexChange, indexChangePercent),
                style = TextStyle(
                    color = ColorProvider(changeColor),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            )
            
            Spacer(modifier = GlanceModifier.height(6.dp))
            
            Box(
                modifier = GlanceModifier
                    .background(statusBgColor)
                    .cornerRadius(4.dp)
                    .padding(horizontal = 6.dp, vertical = 2.dp)
            ) {
                Text(
                    text = marketStatus,
                    style = TextStyle(
                        color = ColorProvider(statusColor),
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }
    }
}

private fun formatIndex(value: Double): String {
    return if (value > 0) String.format("%.2f", value) else "--"
}

private fun formatChange(change: Double, percent: Double): String {
    val sign = if (change >= 0) "+" else ""
    return "$sign${String.format("%.2f", change)} ($sign${String.format("%.2f", percent)}%)"
}
