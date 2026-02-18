package ie.qqrxi.spdrivercalendar

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.SharedPreferences
import android.content.res.Configuration
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
        
        // Check if system is in dark mode
        private fun isSystemDarkMode(context: Context): Boolean {
            return (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        }
        
        // Check if dark mode should be enabled (system dark mode OR app dark mode setting)
        private fun isDarkModeEnabled(context: Context): Boolean {
            // Check system dark mode
            val systemDarkMode = isSystemDarkMode(context)
            
            // Check app's dark mode setting from SharedPreferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val appDarkMode = prefs.getBoolean("flutter.isDarkMode", false)
            
            // Use dark mode if either system or app setting is enabled
            return systemDarkMode || appDarkMode
        }
        
        // Update widget
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.today_shift_widget)
            
            // Apply dark mode colors if app's dark mode is enabled (even if system isn't)
            val isDarkMode = isDarkModeEnabled(context)
            if (isDarkMode && !isSystemDarkMode(context)) {
                // Only apply programmatically if app dark mode is on but system isn't
                // Create a configuration with dark mode enabled to get dark colors
                val config = Configuration(context.resources.configuration)
                config.uiMode = (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or Configuration.UI_MODE_NIGHT_YES
                val darkContext = context.createConfigurationContext(config)
                
                // Apply dark mode colors programmatically using dark context
                views.setTextColor(R.id.widget_header, darkContext.getColor(R.color.widget_header_text))
                views.setTextColor(R.id.widget_time, darkContext.getColor(R.color.widget_text_accent))
                views.setTextColor(R.id.widget_break_container, darkContext.getColor(R.color.widget_text_accent))
                views.setTextColor(R.id.widget_title, darkContext.getColor(R.color.widget_text_primary))
                views.setTextColor(R.id.widget_start_location, darkContext.getColor(R.color.widget_text_primary))
                views.setTextColor(R.id.widget_finish_location, darkContext.getColor(R.color.widget_text_primary))
                views.setTextColor(R.id.widget_buses, darkContext.getColor(R.color.widget_text_primary))
                views.setTextColor(R.id.widget_no_shift, darkContext.getColor(R.color.widget_text_secondary))
                
                // Set background colors using setInt with setBackgroundColor
                views.setInt(R.id.widget_root, "setBackgroundColor", darkContext.getColor(R.color.widget_background))
                // Note: Header background is set via RelativeLayout background attribute in XML
                // We can't easily change it programmatically, but it should use dark colors automatically
            }
            
            // Get today's events
            val todayEvent = getTodayEvent(context)
            
            // Check if today is a holiday and get its type
            val holidayType = getTodayHolidayType(context)
            
            if (todayEvent != null) {
                // Set header to show duty code and routes instead of "Today's Shift"
                val dutyCode = todayEvent.dutyCode
                val routes = todayEvent.routes.filter { !it.isNullOrEmpty() && it != "null" }
                
                if (!dutyCode.isNullOrEmpty()) {
                    // Build header text with duty code and routes in format: "PZ1/74 (C • 39A)"
                    val headerText = if (routes.isNotEmpty()) {
                        val routesText = routes.joinToString(" • ")
                        "$dutyCode ($routesText)"
                    } else {
                        dutyCode
                    }
                    views.setTextViewText(R.id.widget_header, headerText)
                    // Hide title since duty code is in header
                    views.setViewVisibility(R.id.widget_title, android.view.View.GONE)
                } else {
                    views.setTextViewText(R.id.widget_header, "Today's Shift")
                    // Show title if no duty code available
                    views.setTextViewText(R.id.widget_title, todayEvent.title)
                    views.setViewVisibility(R.id.widget_title, android.view.View.VISIBLE)
                }
                
                // Routes container will be used for locations display
                
                // Calculate duration from times
                val duration = calculateDuration(todayEvent.startTime, todayEvent.endTime)
                val timeText = if (duration != null) {
                    "Report ${todayEvent.startTime} - ${todayEvent.endTime} Finish ($duration)"
                } else {
                    "Report ${todayEvent.startTime} - ${todayEvent.endTime} Finish"
                }
                views.setTextViewText(R.id.widget_time, timeText)
                
                // Calculate and show break times with duration and locations (matching time line style)
                val isWorkout = todayEvent.isWorkout
                val hasBreak = !todayEvent.breakStartTime.isNullOrEmpty() && !todayEvent.breakEndTime.isNullOrEmpty()
                if (isWorkout) {
                    views.setTextViewText(R.id.widget_break_container, "Workout")
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.VISIBLE)
                } else if (hasBreak) {
                    // Get break locations
                    val breakStartLoc = if (!todayEvent.startBreakLocation.isNullOrEmpty()) todayEvent.startBreakLocation else ""
                    val breakFinishLoc = if (!todayEvent.finishBreakLocation.isNullOrEmpty()) todayEvent.finishBreakLocation else ""
                    
                    // Calculate break duration
                    val breakDuration = calculateDuration(todayEvent.breakStartTime, todayEvent.breakEndTime)
                    
                    // Build break text with locations: "B Walk 19:07 - 20:07 B Walk (1h 0m)"
                    val breakText = buildString {
                        if (breakStartLoc.isNotEmpty()) {
                            append("$breakStartLoc ")
                        }
                        append("${todayEvent.breakStartTime} - ${todayEvent.breakEndTime}")
                        if (breakFinishLoc.isNotEmpty()) {
                            append(" $breakFinishLoc")
                        }
                        if (breakDuration != null) {
                            append(" ($breakDuration)")
                        }
                    }
                    views.setTextViewText(R.id.widget_break_container, breakText)
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.VISIBLE)
                } else {
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.GONE)
                }
                
                // Show start/finish locations (break locations are now in break time line)
                val startLoc = if (!todayEvent.startLocation.isNullOrEmpty()) todayEvent.startLocation else ""
                val finishLoc = if (!todayEvent.finishLocation.isNullOrEmpty()) todayEvent.finishLocation else ""
                val dutyStartTime = todayEvent.dutyStartTime
                
                val hasLocations = startLoc.isNotEmpty() || finishLoc.isNotEmpty()
                
                if (hasLocations) {
                    // Set start/finish locations
                    if (startLoc.isNotEmpty()) {
                        // Include duty start time if available: "Start Location: B Walk @ 15:21"
                        val startLocText = if (!dutyStartTime.isNullOrEmpty()) {
                            "<b>Start Location:</b> $startLoc @ $dutyStartTime"
                        } else {
                            "<b>Start Location:</b> $startLoc"
                        }
                        views.setTextViewText(R.id.widget_start_location, android.text.Html.fromHtml(startLocText, android.text.Html.FROM_HTML_MODE_LEGACY))
                        views.setViewVisibility(R.id.widget_start_location, android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_start_location, android.view.View.GONE)
                    }
                    
                    if (finishLoc.isNotEmpty()) {
                        views.setTextViewText(R.id.widget_finish_location, android.text.Html.fromHtml("<b>Finish Location:</b> $finishLoc", android.text.Html.FROM_HTML_MODE_LEGACY))
                        views.setViewVisibility(R.id.widget_finish_location, android.view.View.VISIBLE)
                    } else {
                        views.setViewVisibility(R.id.widget_finish_location, android.view.View.GONE)
                    }
                    
                    // Hide break location lines since they're now in the break time
                    views.setViewVisibility(R.id.widget_break_start_location, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_break_finish_location, android.view.View.GONE)
                    
                    views.setViewVisibility(R.id.widget_routes_container, android.view.View.VISIBLE)
                } else {
                    // Hide the entire locations section if no locations available
                    views.setViewVisibility(R.id.widget_routes_container, android.view.View.GONE)
                }
                
                // Hide work time section - it's now shown in the header
                views.setViewVisibility(R.id.widget_work_time_container, android.view.View.GONE)
                
                // Hide duties section - duty code is now shown in header
                views.setViewVisibility(R.id.widget_duties_container, android.view.View.GONE)
                
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
                val hasInfo = (isWorkout || hasBreak) || !todayEvent.workTime.isNullOrEmpty() || 
                             buses.isNotEmpty() || hasLocations
                views.setViewVisibility(R.id.widget_divider, if (hasInfo) android.view.View.VISIBLE else android.view.View.GONE)
                
                // Show holiday indicator if today is a holiday
                if (holidayType != null) {
                    val holidayText = when (holidayType) {
                        "unpaid_leave" -> "Unpaid Leave"
                        "day_in_lieu" -> "Day In Lieu"
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
                views.setTextViewText(R.id.widget_header, "Today's Shift")
                if (holidayType != null) {
                    views.setViewVisibility(R.id.widget_content, android.view.View.VISIBLE)
                    views.setViewVisibility(R.id.widget_no_shift, android.view.View.GONE)
                    val holidayText = when (holidayType) {
                        "unpaid_leave" -> "Unpaid Leave"
                        "day_in_lieu" -> "Day In Lieu"
                        "winter" -> "Winter Holiday"
                        "summer" -> "Summer Holiday"
                        else -> "Holiday"
                    }
                    views.setTextViewText(R.id.widget_title, holidayText)
                    views.setViewVisibility(R.id.widget_time, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_break_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_routes_container, android.view.View.GONE)
                    views.setViewVisibility(R.id.widget_work_time_container, android.view.View.GONE)
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
                        
                        // Get locations directly from event (same as routes)
                        var startLocation: String? = eventObj.optString("startLocation", null)
                        if (startLocation.isNullOrEmpty() || startLocation == "null") {
                            startLocation = null
                        }
                        var finishLocation: String? = eventObj.optString("finishLocation", null)
                        if (finishLocation.isNullOrEmpty() || finishLocation == "null") {
                            finishLocation = null
                        }
                        var startBreakLocation: String? = eventObj.optString("startBreakLocation", null)
                        if (startBreakLocation.isNullOrEmpty() || startBreakLocation == "null") {
                            startBreakLocation = null
                        }
                        var finishBreakLocation: String? = eventObj.optString("finishBreakLocation", null)
                        if (finishBreakLocation.isNullOrEmpty() || finishBreakLocation == "null") {
                            finishBreakLocation = null
                        }
                        
                        // Get duty start time (actual start time, different from report time)
                        // First try to get it directly from event, then fallback to enhanced duties
                        var dutyStartTime: String? = eventObj.optString("dutyStartTime", null)
                        if (dutyStartTime.isNullOrEmpty() || dutyStartTime == "null") {
                            dutyStartTime = null
                        }
                        
                        // Also check enhanced duties for routes (for spare shifts)
                        val enhancedDuties = eventObj.optJSONArray("enhancedAssignedDuties")
                        if (enhancedDuties != null && enhancedDuties.length() > 0) {
                            for (j in 0 until enhancedDuties.length()) {
                                try {
                                    val dutyObj = enhancedDuties.getJSONObject(j)
                                    val dutyCode = dutyObj.optString("dutyCode", null)
                                    if (!dutyCode.isNullOrEmpty() && !duties.contains(dutyCode)) {
                                        duties.add(dutyCode)
                                    }
                                    
                                    // Extract duty start time from first duty if not already found (fallback)
                                    if (dutyStartTime == null) {
                                        val extractedStartTime = dutyObj.optString("startTime", null)
                                        if (!extractedStartTime.isNullOrEmpty() && extractedStartTime != "null") {
                                            dutyStartTime = extractedStartTime
                                        }
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
                        var isWorkout = false
                        val breakStartTimeObj = eventObj.opt("breakStartTime")
                        val breakEndTimeObj = eventObj.opt("breakEndTime")
                        
                        // Check if break times are stored as strings (for workouts)
                        if (breakStartTimeObj is String) {
                            val breakStartStr = breakStartTimeObj.lowercase()
                            if (breakStartStr == "workout" || breakStartStr == "nan" || breakStartStr.isEmpty()) {
                                isWorkout = true
                            }
                        }
                        if (breakEndTimeObj is String) {
                            val breakEndStr = breakEndTimeObj.lowercase()
                            if (breakEndStr == "workout" || breakEndStr == "nan" || breakEndStr.isEmpty()) {
                                isWorkout = true
                            }
                        }
                        
                        // Try to parse as JSON objects (normal break times)
                        if (!isWorkout && breakStartTimeObj is JSONObject && !breakStartTimeObj.toString().equals("null")) {
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
                        if (!isWorkout && breakEndTimeObj is JSONObject && !breakEndTimeObj.toString().equals("null")) {
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
                        
                        // Check if break times are null for PZ duties (indicates workout)
                        // PZ duties should have break times unless they're workouts
                        if (!isWorkout) {
                            val breakStartIsNull = breakStartTimeObj == null || breakStartTimeObj == JSONObject.NULL || eventObj.isNull("breakStartTime")
                            val breakEndIsNull = breakEndTimeObj == null || breakEndTimeObj == JSONObject.NULL || eventObj.isNull("breakEndTime")
                            
                            if (breakStartIsNull || breakEndIsNull) {
                                // Check if this is a PZ duty
                                val isPZDuty = title.startsWith("PZ") || title.matches(Regex("^\\d+/.*"))
                                if (isPZDuty) {
                                    // PZ duty with no break times is likely a workout
                                    isWorkout = true
                                }
                            }
                        }
                        
                        // Also check if break times are equal (indicates workout)
                        if (!isWorkout && breakStartTime != null && breakEndTime != null && breakStartTime == breakEndTime) {
                            isWorkout = true
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
                        
                        // Extract duty code for header display
                        // For PZ duties, title is usually the duty code (e.g., "PZ1/74")
                        // Remove "Shift: " prefix if present
                        var dutyCode: String? = null
                        var cleanTitle = title.replace("Shift: ", "").trim()
                        
                        // Check if title is a PZ duty code (starts with PZ or matches pattern like "1/74")
                        if (cleanTitle.startsWith("PZ") || cleanTitle.matches(Regex("^\\d+/.*"))) {
                            dutyCode = cleanTitle
                        } else if (duties.isNotEmpty()) {
                            // For spare shifts or other shifts, use first duty code
                            dutyCode = duties[0]
                            // Remove "UNI:" prefix if present
                            if (dutyCode.startsWith("UNI:")) {
                                dutyCode = dutyCode.substring(4)
                            }
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
                            notes = null,  // Don't store notes
                            isWorkout = isWorkout,
                            dutyCode = dutyCode,
                            startLocation = startLocation,
                            finishLocation = finishLocation,
                            startBreakLocation = startBreakLocation,
                            finishBreakLocation = finishBreakLocation,
                            dutyStartTime = dutyStartTime
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
                   title == "CPC" ||
                   title == "22B/01" ||
                   title.matches(Regex("^\\d+/.*"))
        }
        
        private fun parseHolidayDate(dateStr: String): Date? {
            if (dateStr.isEmpty()) return null
            val formats = listOf(
                "yyyy-MM-dd'T'HH:mm:ss.SSS",
                "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
                "yyyy-MM-dd'T'HH:mm:ss",
                "yyyy-MM-dd"
            )
            for (format in formats) {
                try {
                    SimpleDateFormat(format, Locale.US).parse(dateStr)?.let { return it }
                } catch (_: Exception) { }
            }
            val datePart = if (dateStr.contains("T")) dateStr.split("T")[0] else dateStr
            return try { SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(datePart) } catch (_: Exception) { null }
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
                            val startDate = parseHolidayDate(startDateStr)
                            val endDate = parseHolidayDate(endDateStr)
                            
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
    val notes: String?,
    val isWorkout: Boolean = false,
    val dutyCode: String? = null,
    val startLocation: String? = null,
    val finishLocation: String? = null,
    val startBreakLocation: String? = null,
    val finishBreakLocation: String? = null,
    val dutyStartTime: String? = null
)

