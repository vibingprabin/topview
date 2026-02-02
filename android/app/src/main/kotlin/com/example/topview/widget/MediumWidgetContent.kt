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
import androidx.glance.appwidget.action.actionRunCallback
import androidx.glance.Image
import androidx.glance.ImageProvider
import androidx.compose.ui.graphics.Color
import com.example.topview.R

private val DarkNavy = Color(0xFF2B2D42)
private val RichBlue = Color(0xFF118AB2)
private val PositiveGreen = Color(0xFF06D6A0)
private val NegativeRed = Color(0xFFEF476F)
private val TextPrimary = Color(0xFFFFFFFF)
private val TextSecondary = Color(0xFFB0B0B0)
private val CardBackground = Color(0xFF3D3F5C)
private val StatusGreenBg = Color(0x3306D6A0)
private val StatusGrayBg = Color(0x33B0B0B0)
private val RichBlueBg = Color(0x33118AB2)

@Composable
fun MediumWidgetContent(
    nepseIndex: Double,
    indexChange: Double,
    indexChangePercent: Double,
    marketStatus: String,
    portfolioValue: Double,
    portfolioChange: Double,
    portfolioChangePercent: Double
) {
    val isIndexPositive = indexChange >= 0
    val indexChangeColor = if (isIndexPositive) PositiveGreen else NegativeRed
    val isPortfolioPositive = portfolioChange >= 0
    val portfolioChangeColor = if (isPortfolioPositive) PositiveGreen else NegativeRed
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
            .padding(16.dp)
    ) {
        Column(
            modifier = GlanceModifier.fillMaxSize()
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "TopView",
                    style = TextStyle(
                        color = ColorProvider(RichBlue),
                        fontSize = 14.sp,
                        fontWeight = FontWeight.Bold
                    ),
                    modifier = GlanceModifier.clickable(actionStartActivity(openAppIntent))
                )
                
                Spacer(modifier = GlanceModifier.defaultWeight())
                
                Box(
                    modifier = GlanceModifier
                        .background(statusBgColor)
                        .cornerRadius(4.dp)
                        .padding(horizontal = 8.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = marketStatus,
                        style = TextStyle(
                            color = ColorProvider(statusColor),
                            fontSize = 10.sp,
                            fontWeight = FontWeight.Medium
                        )
                    )
                }
                
                Spacer(modifier = GlanceModifier.width(8.dp))
                
                Box(
                    modifier = GlanceModifier
                        .size(24.dp)
                        .background(RichBlueBg)
                        .cornerRadius(6.dp)
                        .clickable(actionRunCallback<RefreshCallback>()),
                    contentAlignment = Alignment.Center
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_refresh),
                        contentDescription = "Refresh",
                        modifier = GlanceModifier.size(16.dp)
                    )
                }
            }
            
            Spacer(modifier = GlanceModifier.height(12.dp))
            
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(actionStartActivity(openAppIntent))
            ) {
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .background(CardBackground)
                        .cornerRadius(12.dp)
                        .padding(12.dp)
                ) {
                    Column {
                        Text(
                            text = "NEPSE Index",
                            style = TextStyle(
                                color = ColorProvider(TextSecondary),
                                fontSize = 10.sp
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = formatIndex(nepseIndex),
                            style = TextStyle(
                                color = ColorProvider(TextPrimary),
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = formatChange(indexChange, indexChangePercent),
                            style = TextStyle(
                                color = ColorProvider(indexChangeColor),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium
                            )
                        )
                    }
                }
                
                Spacer(modifier = GlanceModifier.width(8.dp))
                
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .background(CardBackground)
                        .cornerRadius(12.dp)
                        .padding(12.dp)
                ) {
                    Column {
                        Text(
                            text = "Portfolio",
                            style = TextStyle(
                                color = ColorProvider(TextSecondary),
                                fontSize = 10.sp
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(4.dp))
                        Text(
                            text = formatCurrency(portfolioValue),
                            style = TextStyle(
                                color = ColorProvider(TextPrimary),
                                fontSize = 18.sp,
                                fontWeight = FontWeight.Bold
                            )
                        )
                        Spacer(modifier = GlanceModifier.height(2.dp))
                        Text(
                            text = formatChangeWithPercent(portfolioChange, portfolioChangePercent),
                            style = TextStyle(
                                color = ColorProvider(portfolioChangeColor),
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium
                            )
                        )
                    }
                }
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

private fun formatCurrency(value: Double): String {
    return when {
        value >= 10000000 -> String.format("%.2f Cr", value / 10000000)
        value >= 100000 -> String.format("%.2f L", value / 100000)
        value >= 1000 -> String.format("%.1f K", value / 1000)
        value > 0 -> String.format("%.0f", value)
        else -> "--"
    }
}

private fun formatChangeWithPercent(change: Double, percent: Double): String {
    val sign = if (change >= 0) "+" else ""
    return "$sign${String.format("%.2f", percent)}%"
}
