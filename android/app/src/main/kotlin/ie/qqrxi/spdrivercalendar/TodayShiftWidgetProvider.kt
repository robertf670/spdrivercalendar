package ie.qqrxi.spdrivercalendar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import org.json.JSONObject
import org.json.JSONArray
import java.text.SimpleDateFormat
import java.util.*

class TodayShiftWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val EVENTS_KEY = "flutter.events"
        private const val HOLIDAYS_KEY = "flutter.holidays"
        const val ACTION_REFRESH = "ie.qqrxi.spdrivercalendar.ACTION_REFRESH"
        
        // Update widget
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.today_shift_widget)
            
            // Get today's events
            val todayEvent = getTodayEvent(context)
            
            // Check if today is a holiday and get its type
            val holidayType = getTodayHolidayType(context)
            
            if (todayEvent != null) {
                // Display shift information
                views.setTextViewText(R.id.widget_title, todayEvent.title)
                
                // Calculate duration from times
                val duration = calculateDuration(todayEvent.startTime, todayEvent.endTime)
                val timeText = if (duration != null) {
                    "${todayEvent.startTime} - ${todayEvent.endTime} ($duration)"
                } else {
                    "${todayEvent.startTime} - ${todayEvent.endTime}"
                }
                views.setTextViewText(R.id.widget_time, timeText)
                
                // Show break times if available
                val hasBreak = !todayEvent.breakStartTime.isNullOrEmpty() && !todayEvent.breakEndTime.isNullOrEmpty()
                if (hasBreak) {
                    views.setTextViewText(R.id.widget_break, "${todayEvent.breakStartTime}-${todayEvent.breakEndTime}")
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.GONE)
                }
                
                // Show routes/locations if available
                val routes = todayEvent.routes.filter { !it.isNullOrEmpty() && it != "null" }
                if (routes.isNotEmpty()) {
                    val routesText = routes.joinToString(", ")
                    views.setTextViewText(R.id.widget_routes, routesText)
                    views.setViewVisibility(R.id.widget_routes_container, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_routes_container, android.view.View.GONE)
                }
                
                // Show work time if available
                if (!todayEvent.workTime.isNullOrEmpty()) {
                    views.setTextViewText(R.id.widget_work_time, todayEvent.workTime)
                    views.setViewVisibility(R.id.widget_work_time_container, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_work_time_container, android.view.View.GONE)
                }
                
                // Show duties if available
                val duties = todayEvent.duties.filter { !it.isNullOrEmpty() }
                if (duties.isNotEmpty()) {
                    val dutiesText = duties.joinToString(", ")
                    views.setTextViewText(R.id.widget_duties, dutiesText)
                    views.setViewVisibility(R.id.widget_duties_container, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_duties_container, android.view.View.GONE)
                }
                
                // Show bus assignments if available
                val buses = todayEvent.buses.filter { !it.isNullOrEmpty() && it != "null" }
                if (buses.isNotEmpty()) {
                    val busesText = buses.joinToString(", ")
                    views.setTextViewText(R.id.widget_buses, busesText)
                    views.setViewVisibility(R.id.widget_buses_container, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_buses_container, android.view.View.GONE)
                }
                
                // Hide combined info line (using individual sections now)
                views.setViewVisibility(R.id.widget_info, android.view.View.GONE)
                
                // Show divider only if we have info to show
                val hasInfo = hasBreak || routes.isNotEmpty() || !todayEvent.workTime.isNullOrEmpty() || 
                             duties.isNotEmpty() || buses.isNotEmpty()
                views.setViewVisibility(R.id.widget_divider, if (hasInfo) android.view.View.VISIBLE else android.view.View.GONE)
                
                // Show holiday indicator if today is a holiday
                if (holidayType != null) {
                    val holidayText = when (holidayType) {
                        "unpaid_leave" -> "Unpaid Leave"
                        "winter" -> "Winter Holiday"
                        "summer" -> "Summer Holiday"
                        else -> "Holiday"
                    }
                    views.setTextViewText(R.id.widget_title, "${todayEvent.title} ($holidayText)")
                }
                
                views.setViewVisibility(R.id.widget_no_shift, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_content, android.view.View.VISIBLE)
            } else {
                // No shift today - check if it's a holiday
                if (holidayType != null) {
                    views.setViewVisibility(R.id.widget_content, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_no_shift, android.view.View.GONE)
                    val holidayText = when (holidayType) {
                        "unpaid_leave" -> "Unpaid Leave"
                        "winter" -> "Winter Holiday"
                        "summer" -> "Summer Holiday"
                        else -> "Holiday"
                    }
                    views.setTextViewText(R.id.widget_title, holidayText)
                    views.setViewVisibility(R.id.widget_time, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_routes_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_work_time_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_duties_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_buses_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_divider, android.view.View.GONE)
                } else {
                    views.setViewVisibility(R.id.widget_no_shift, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_content, android.view.View.GONE)
                }
            }
            
            // Set up click intent to open the app
            val intent = android.content.Intent(context, MainActivity::class.java)
            intent.flags = android.content.Intent.FLAG_ACTIVITY_NEW_TASK or android.content.Intent.FLAG_ACTIVITY_CLEAR_TASK
            val pendingIntent = android.app.PendingIntent.getActivity(
                context,
                0,
                intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)
            
            // Set up refresh button
            val refreshIntent = android.content.Intent(context, TodayShiftWidgetProvider::class.java).apply {
                action = ACTION_REFRESH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val refreshPendingIntent = android.app.PendingIntent.getBroadcast(
                context,
                appWidgetId,
                refreshIntent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)
            
            // Update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
        
        private fun getTodayEvent(context: Context): TodayEvent? {
            try {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                // Try with flutter. prefix first (Flutter's SharedPreferences format)
                var eventsJson = prefs.getString(EVENTS_KEY, null)
                // Fallback to without prefix
                if (eventsJson == null) {
                    eventsJson = prefs.getString("events", null)
                }
                if (eventsJson == null || eventsJson.isEmpty()) return null
                
                val today = Calendar.getInstance()
                val todayKey = formatDateKey(today.time)
                
                // Parse the JSON string - it's a map of date strings to arrays of events
                val jsonObject = JSONObject(eventsJson)
                
                // Try exact match first (in case format is different)
                var eventsArray = jsonObject.optJSONArray(todayKey)
                
                // If not found, try ISO8601 format matching
                // EventService uses ISO8601 format (e.g., "2024-01-15T00:00:00.000")
                if (eventsArray == null) {
                    val keys = jsonObject.keys()
                    while (keys.hasNext()) {
                        val key = keys.next()
                        // Extract date part from ISO8601 string (everything before 'T')
                        if (key.contains("T")) {
                            val datePart = key.split("T")[0]
                            if (datePart == todayKey) {
                                eventsArray = jsonObject.optJSONArray(key)
                                break
                            }
                        }
                    }
                }
                
                if (eventsArray == null) return null
                
                // Find the first work shift for today
                for (i in 0 until eventsArray.length()) {
                    val eventObj = eventsArray.getJSONObject(i)
                    val title = eventObj.getString("title")
                    
                    // Check if it's a work shift
                    if (isWorkShift(title)) {
                        val startTimeObj = eventObj.getJSONObject("startTime")
                        val endTimeObj = eventObj.getJSONObject("endTime")
                        val startTime = String.format(
                            "%02d:%02d",
                            startTimeObj.getInt("hour"),
                            startTimeObj.getInt("minute")
                        )
                        val endTime = String.format(
                            "%02d:%02d",
                            endTimeObj.getInt("hour"),
                            endTimeObj.getInt("minute")
                        )
                        
                        // Get duties
                        val duties = mutableListOf<String>()
                        val assignedDuties = eventObj.optJSONArray("assignedDuties")
                        if (assignedDuties != null) {
                            for (j in 0 until assignedDuties.length()) {
                                duties.add(assignedDuties.getString(j))
                            }
                        }
                        
                        // Get routes - first check if stored directly in event
                        val routes = mutableListOf<String>()
                        val routesArray = eventObj.optJSONArray("routes")
                        if (routesArray != null) {
                            for (j in 0 until routesArray.length()) {
                                val route = routesArray.getString(j)
                                if (!route.isNullOrEmpty() && route != "null" && !routes.contains(route)) {
                                    routes.add(route)
                                }
                            }
                        }
                        
                        // Also check enhanced duties for routes/locations (for spare shifts)
                        val enhancedDuties = eventObj.optJSONArray("enhancedAssignedDuties")
                        if (enhancedDuties != null && enhancedDuties.length() > 0) {
                            for (j in 0 until enhancedDuties.length()) {
                                try {
                                    val dutyObj = enhancedDuties.getJSONObject(j)
                                    val dutyCode = dutyObj.optString("dutyCode", null)
                                    if (!dutyCode.isNullOrEmpty() && !duties.contains(dutyCode)) {
                                        duties.add(dutyCode)
                                    }
                                    
                                    // Extract location/route if available - check multiple ways
                                    var location = dutyObj.optString("location", null)
                                    if (location.isNullOrEmpty() || location == "null") {
                                        location = null
                                    }
                                    if (!location.isNullOrEmpty() && location != "null" && !routes.contains(location)) {
                                        routes.add(location)
                                    }
                                } catch (e: Exception) {
                                    // Skip invalid duty object
                                }
                            }
                        }
                        
                        // Get bus assignments
                        val buses = mutableListOf<String>()
                        val busAssignments = eventObj.optJSONObject("busAssignments")
                        if (busAssignments != null) {
                            val keys = busAssignments.keys()
                            while (keys.hasNext()) {
                                val key = keys.next()
                                if (!busAssignments.isNull(key)) {
                                    val busValue = busAssignments.getString(key)
                                    if (busValue.isNotEmpty() && busValue != "null" && !buses.contains(busValue)) {
                                        buses.add(busValue)
                                    }
                                }
                            }
                        }
                        
                        // Check for firstHalfBus and secondHalfBus
                        if (!eventObj.isNull("firstHalfBus")) {
                            val firstHalfBus = eventObj.getString("firstHalfBus")
                            if (firstHalfBus.isNotEmpty() && firstHalfBus != "null" && !buses.contains(firstHalfBus)) {
                                buses.add(firstHalfBus)
                            }
                        }
                        if (!eventObj.isNull("secondHalfBus")) {
                            val secondHalfBus = eventObj.getString("secondHalfBus")
                            if (secondHalfBus.isNotEmpty() && secondHalfBus != "null" && !buses.contains(secondHalfBus)) {
                                buses.add(secondHalfBus)
                            }
                        }
                        
                        // Get break times - check for both UNI shifts and PZ shifts
                        var breakStartTime: String? = null
                        var breakEndTime: String? = null
                        val breakStartTimeObj = eventObj.optJSONObject("breakStartTime")
                        val breakEndTimeObj = eventObj.optJSONObject("breakEndTime")
                        if (breakStartTimeObj != null && !breakStartTimeObj.toString().equals("null")) {
                            try {
                                breakStartTime = String.format(
                                    "%02d:%02d",
                                    breakStartTimeObj.getInt("hour"),
                                    breakStartTimeObj.getInt("minute")
                                )
                            } catch (e: Exception) {
                                // Break time not available
                            }
                        }
                        if (breakEndTimeObj != null && !breakEndTimeObj.toString().equals("null")) {
                            try {
                                breakEndTime = String.format(
                                    "%02d:%02d",
                                    breakEndTimeObj.getInt("hour"),
                                    breakEndTimeObj.getInt("minute")
                                )
                            } catch (e: Exception) {
                                // Break time not available
                            }
                        }
                        
                        // Get work time (for PZ shifts) - stored in minutes
                        var workTime: String? = null
                        try {
                            val workTimeMinutes = eventObj.optInt("workTime", -1)
                            if (workTimeMinutes > 0) {
                                val hours = workTimeMinutes / 60
                                val minutes = workTimeMinutes % 60
                                workTime = if (hours > 0) {
                                    String.format("%dh %dm", hours, minutes)
                                } else {
                                    String.format("%dm", minutes)
                                }
                            }
                        } catch (e: Exception) {
                            // Work time not available
                        }
                        
                        return TodayEvent(
                            title = title,
                            startTime = startTime,
                            endTime = endTime,
                            duties = duties,
                            buses = buses,
                            breakStartTime = breakStartTime,
                            breakEndTime = breakEndTime,
                            workTime = workTime,
                            routes = routes,
                            notes = null  // Don't store notes
                        )
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            
            return null
        }
        
        private fun formatDateKey(date: Date): String {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            return sdf.format(date)
        }
        
        private fun calculateDuration(startTime: String, endTime: String): String? {
            try {
                val startParts = startTime.split(":")
                val endParts = endTime.split(":")
                if (startParts.size != 2 || endParts.size != 2) return null
                
                val startHour = startParts[0].toInt()
                val startMin = startParts[1].toInt()
                val endHour = endParts[0].toInt()
                val endMin = endParts[1].toInt()
                
                var totalMinutes = (endHour * 60 + endMin) - (startHour * 60 + startMin)
                // Handle overnight shifts
                if (totalMinutes < 0) {
                    totalMinutes += 24 * 60
                }
                
                val hours = totalMinutes / 60
                val minutes = totalMinutes % 60
                
                return if (hours > 0) {
                    String.format("%dh %dm", hours, minutes)
                } else {
                    String.format("%dm", minutes)
                }
            } catch (e: Exception) {
                return null
            }
        }
        
        private fun isWorkShift(title: String): Boolean {
            return title.startsWith("Shift:") ||
                   title.startsWith("SP") ||
                   title.startsWith("PZ") ||
                   title.startsWith("BusCheck") ||
                   title == "TRAIN23/24" ||
                   title == "CPC" ||
                   title == "22B/01" ||
                   title.matches(Regex("^\\d+/.*"))
        }
        
        private fun getTodayHolidayType(context: Context): String? {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val holidaysJson = prefs.getString(HOLIDAYS_KEY, null) ?: prefs.getString("holidays", null)
            
            if (holidaysJson == null || holidaysJson.isEmpty()) return null
            
            try {
                val jsonArray = JSONArray(holidaysJson)
                val today = Calendar.getInstance()
                val todayYear = today.get(Calendar.YEAR)
                val todayMonth = today.get(Calendar.MONTH)
                val todayDay = today.get(Calendar.DAY_OF_MONTH)
                
                for (i in 0 until jsonArray.length()) {
                    val holidayObj = jsonArray.getJSONObject(i)
                    val startDateStr = holidayObj.optString("startDate", "")
                    val endDateStr = holidayObj.optString("endDate", "")
                    val type = holidayObj.optString("type", "other")
                    
                    if (startDateStr.isNotEmpty() && endDateStr.isNotEmpty()) {
                        try {
                            val startDate = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(startDateStr)
                                ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(startDateStr)
                            val endDate = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", Locale.US).parse(endDateStr)
                                ?: SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(endDateStr)
                            
                            if (startDate != null && endDate != null) {
                                val startCal = Calendar.getInstance()
                                startCal.time = startDate
                                val endCal = Calendar.getInstance()
                                endCal.time = endDate
                                
                                val checkDate = Calendar.getInstance()
                                checkDate.set(todayYear, todayMonth, todayDay, 0, 0, 0)
                                checkDate.set(Calendar.MILLISECOND, 0)
                                
                                val startDateCal = Calendar.getInstance()
                                startDateCal.set(startCal.get(Calendar.YEAR), startCal.get(Calendar.MONTH), 
                                               startCal.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
                                startDateCal.set(Calendar.MILLISECOND, 0)
                                
                                val endDateCal = Calendar.getInstance()
                                endDateCal.set(endCal.get(Calendar.YEAR), endCal.get(Calendar.MONTH), 
                                             endCal.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
                                endDateCal.set(Calendar.MILLISECOND, 0)
                                
                                if (!checkDate.before(startDateCal) && !checkDate.after(endDateCal)) {
                                    return type
                                }
                            }
                        } catch (e: Exception) {
                            // Skip invalid date format
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            
            return null
        }
    }
    
    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        
        if (intent.action == ACTION_REFRESH) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID
            )
            
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }
    }
    
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }
    
    override fun onEnabled(context: Context) {
        // Enter relevant functionality for when the first widget is created
    }
    
    override fun onDisabled(context: Context) {
        // Enter relevant functionality for when the last widget is disabled
    }
}

// Data class for today's event
data class TodayEvent(
    val title: String,
    val startTime: String,
    val endTime: String,
    val duties: List<String>,
    val buses: List<String>,
    val breakStartTime: String?,
    val breakEndTime: String?,
    val workTime: String?,
    val routes: List<String>,
    val notes: String?
)

