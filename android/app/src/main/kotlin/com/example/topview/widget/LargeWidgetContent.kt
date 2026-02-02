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
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.example.topview.R

// Theme colors
private val DarkNavy = Color(0xFF2B2D42)
private val RichBlue = Color(0xFF118AB2)
private val PositiveGreen = Color(0xFF06D6A0)
private val NegativeRed = Color(0xFFEF476F)
private val TextPrimary = Color(0xFFFFFFFF)
private val TextSecondary = Color(0xFFB0B0B0)
private val CardBackground = Color(0xFF3D3F5C)
private val AccentOrange = Color(0xFFFF9F1C)
private val StatusGreenBg = Color(0x3306D6A0)
private val StatusGrayBg = Color(0x33B0B0B0)
private val StatusOrangeBg = Color(0x33FF9F1C)
private val RichBlueBg = Color(0x33118AB2)

data class HoldingData(
    val symbol: String,
    val quantity: Int,
    val currentValue: Double,
    val unrealizedPL: Double,
    val unrealizedPLPercent: Double
)

data class IpoData(
    val companyName: String,
    val symbol: String,
    val openDate: String,
    val closeDate: String,
    val status: String,
    val pricePerUnit: Double,
    val type: String
)

@Composable
fun LargeWidgetContent(
    nepseIndex: Double,
    indexChange: Double,
    indexChangePercent: Double,
    marketStatus: String,
    portfolioValue: Double,
    portfolioChange: Double,
    portfolioChangePercent: Double,
    topHoldingsJson: String,
    upcomingIposJson: String,
    lastUpdate: String
) {
    val isIndexPositive = indexChange >= 0
    val indexChangeColor = if (isIndexPositive) PositiveGreen else NegativeRed
    val isPortfolioPositive = portfolioChange >= 0
    val portfolioChangeColor = if (isPortfolioPositive) PositiveGreen else NegativeRed
    val statusColor = if (marketStatus == "OPEN") PositiveGreen else TextSecondary
    val statusBgColor = if (marketStatus == "OPEN") StatusGreenBg else StatusGrayBg
    
    val holdings = parseHoldings(topHoldingsJson)
    val ipos = parseIpos(upcomingIposJson)
    
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
            .padding(14.dp)
    ) {
        Column(
            modifier = GlanceModifier.fillMaxSize()
        ) {
            Row(
                modifier = GlanceModifier.fillMaxWidth(),
                horizontalAlignment = Alignment.Horizontal.CenterHorizontally,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = GlanceModifier.clickable(actionStartActivity(openAppIntent))
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_chart),
                        contentDescription = "TopView",
                        modifier = GlanceModifier.size(18.dp)
                    )
                    Spacer(modifier = GlanceModifier.width(6.dp))
                    Text(
                        text = "TopView",
                        style = TextStyle(
                            color = ColorProvider(RichBlue),
                            fontSize = 15.sp,
                            fontWeight = FontWeight.Bold
                        )
                    )
                }
                
                Spacer(modifier = GlanceModifier.defaultWeight())
                
                Box(
                    modifier = GlanceModifier
                        .background(statusBgColor)
                        .cornerRadius(4.dp)
                        .padding(horizontal = 8.dp, vertical = 3.dp)
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
                        .size(28.dp)
                        .background(RichBlueBg)
                        .cornerRadius(6.dp)
                        .clickable(actionRunCallback<RefreshCallback>()),
                    contentAlignment = Alignment.Center
                ) {
                    Image(
                        provider = ImageProvider(R.drawable.ic_refresh),
                        contentDescription = "Refresh",
                        modifier = GlanceModifier.size(18.dp)
                    )
                }
            }
            
            Spacer(modifier = GlanceModifier.height(10.dp))
            
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .clickable(actionStartActivity(openAppIntent))
            ) {
                Box(
                    modifier = GlanceModifier
                        .defaultWeight()
                        .background(CardBackground)
                        .cornerRadius(10.dp)
                        .padding(10.dp)
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_trending),
                                contentDescription = "Index",
                                modifier = GlanceModifier.size(14.dp)
                            )
                            Spacer(modifier = GlanceModifier.width(4.dp))
                            Text(
                                text = "NEPSE",
                                style = TextStyle(
                                    color = ColorProvider(TextSecondary),
                                    fontSize = 10.sp
                                )
                            )
                        }
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
                                fontSize = 10.sp,
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
                        .cornerRadius(10.dp)
                        .padding(10.dp)
                ) {
                    Column {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Image(
                                provider = ImageProvider(R.drawable.ic_portfolio),
                                contentDescription = "Portfolio",
                                modifier = GlanceModifier.size(14.dp)
                            )
                            Spacer(modifier = GlanceModifier.width(4.dp))
                            Text(
                                text = "Portfolio",
                                style = TextStyle(
                                    color = ColorProvider(TextSecondary),
                                    fontSize = 10.sp
                                )
                            )
                        }
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
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Medium
                            )
                        )
                    }
                }
            }
            
            Spacer(modifier = GlanceModifier.height(10.dp))
            
            Row(
                modifier = GlanceModifier
                    .fillMaxWidth()
                    .defaultWeight()
                    .clickable(actionStartActivity(openAppIntent))
            ) {
                Column(
                    modifier = GlanceModifier.defaultWeight()
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_holdings),
                            contentDescription = "Holdings",
                            modifier = GlanceModifier.size(12.dp)
                        )
                        Spacer(modifier = GlanceModifier.width(4.dp))
                        Text(
                            text = "Holdings",
                            style = TextStyle(
                                color = ColorProvider(TextSecondary),
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Medium
                            )
                        )
                    }
                    
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    
                    if (holdings.isNotEmpty()) {
                        Column(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .background(CardBackground)
                                .cornerRadius(8.dp)
                                .padding(8.dp)
                        ) {
                            holdings.take(3).forEachIndexed { index, holding ->
                                if (index > 0) {
                                    Spacer(modifier = GlanceModifier.height(6.dp))
                                }
                                HoldingRowCompact(holding)
                            }
                        }
                    } else {
                        Box(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .background(CardBackground)
                                .cornerRadius(8.dp)
                                .padding(12.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No holdings",
                                style = TextStyle(
                                    color = ColorProvider(TextSecondary),
                                    fontSize = 10.sp
                                )
                            )
                        }
                    }
                }
                
                Spacer(modifier = GlanceModifier.width(8.dp))
                
                Column(
                    modifier = GlanceModifier.defaultWeight()
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Image(
                            provider = ImageProvider(R.drawable.ic_ipo),
                            contentDescription = "IPOs",
                            modifier = GlanceModifier.size(12.dp)
                        )
                        Spacer(modifier = GlanceModifier.width(4.dp))
                        Text(
                            text = "Upcoming IPOs",
                            style = TextStyle(
                                color = ColorProvider(TextSecondary),
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Medium
                            )
                        )
                    }
                    
                    Spacer(modifier = GlanceModifier.height(6.dp))
                    
                    if (ipos.isNotEmpty()) {
                        Column(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .background(CardBackground)
                                .cornerRadius(8.dp)
                                .padding(8.dp)
                        ) {
                            ipos.take(3).forEachIndexed { index, ipo ->
                                if (index > 0) {
                                    Spacer(modifier = GlanceModifier.height(6.dp))
                                }
                                IpoRowCompact(ipo)
                            }
                        }
                    } else {
                        Box(
                            modifier = GlanceModifier
                                .fillMaxWidth()
                                .background(CardBackground)
                                .cornerRadius(8.dp)
                                .padding(12.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = "No IPOs",
                                style = TextStyle(
                                    color = ColorProvider(TextSecondary),
                                    fontSize = 10.sp
                                )
                            )
                        }
                    }
                }
            }
            
            Spacer(modifier = GlanceModifier.height(6.dp))
            
            // Footer with last update time
            if (lastUpdate.isNotEmpty()) {
                Row(
                    modifier = GlanceModifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.Horizontal.End
                ) {
                    Text(
                        text = "Updated: ${formatTime(lastUpdate)}",
                        style = TextStyle(
                            color = ColorProvider(TextSecondary),
                            fontSize = 8.sp
                        )
                    )
                }
            }
        }
    }
}

@Composable
private fun HoldingRowCompact(holding: HoldingData) {
    val changeColor = if (holding.unrealizedPL >= 0) PositiveGreen else NegativeRed
    
    Row(
        modifier = GlanceModifier.fillMaxWidth(),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = GlanceModifier.defaultWeight()
        ) {
            Text(
                text = holding.symbol,
                style = TextStyle(
                    color = ColorProvider(TextPrimary),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                )
            )
            Text(
                text = "${holding.quantity} units",
                style = TextStyle(
                    color = ColorProvider(TextSecondary),
                    fontSize = 9.sp
                )
            )
        }
        
        Text(
            text = formatPercent(holding.unrealizedPLPercent),
            style = TextStyle(
                color = ColorProvider(changeColor),
                fontSize = 10.sp,
                fontWeight = FontWeight.Medium
            )
        )
    }
}

@Composable
private fun IpoRowCompact(ipo: IpoData) {
    val statusColor = when(ipo.status.lowercase()) {
        "open" -> PositiveGreen
        "upcoming" -> AccentOrange
        else -> TextSecondary
    }
    val statusBgColor = when(ipo.status.lowercase()) {
        "open" -> StatusGreenBg
        "upcoming" -> StatusOrangeBg
        else -> StatusGrayBg
    }
    
    Column(
        modifier = GlanceModifier.fillMaxWidth()
    ) {
        Row(
            modifier = GlanceModifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = ipo.symbol.ifEmpty { ipo.companyName.take(8) },
                style = TextStyle(
                    color = ColorProvider(TextPrimary),
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium
                ),
                modifier = GlanceModifier.defaultWeight()
            )
            
            Box(
                modifier = GlanceModifier
                    .background(statusBgColor)
                    .cornerRadius(3.dp)
                    .padding(horizontal = 4.dp, vertical = 1.dp)
            ) {
                Text(
                    text = ipo.status.uppercase().take(4),
                    style = TextStyle(
                        color = ColorProvider(statusColor),
                        fontSize = 8.sp,
                        fontWeight = FontWeight.Medium
                    )
                )
            }
        }
        
        Text(
            text = "${ipo.openDate} - ${ipo.closeDate}",
            style = TextStyle(
                color = ColorProvider(TextSecondary),
                fontSize = 8.sp
            )
        )
    }
}

private fun parseHoldings(json: String): List<HoldingData> {
    return try {
        if (json.isEmpty() || json == "[]") {
            emptyList()
        } else {
            val type = object : TypeToken<List<HoldingData>>() {}.type
            Gson().fromJson(json, type)
        }
    } catch (e: Exception) {
        emptyList()
    }
}

private fun parseIpos(json: String): List<IpoData> {
    return try {
        if (json.isEmpty() || json == "[]") {
            emptyList()
        } else {
            val type = object : TypeToken<List<IpoData>>() {}.type
            Gson().fromJson(json, type)
        }
    } catch (e: Exception) {
        emptyList()
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

private fun formatPercent(value: Double): String {
    val sign = if (value >= 0) "+" else ""
    return "$sign${String.format("%.2f", value)}%"
}

private fun formatTime(isoString: String): String {
    return try {
        val parts = isoString.split("T")
        if (parts.size >= 2) {
            val timeParts = parts[1].split(":")
            if (timeParts.size >= 2) {
                "${timeParts[0]}:${timeParts[1]}"
            } else {
                isoString
            }
        } else {
            isoString
        }
    } catch (e: Exception) {
        isoString
    }
}
