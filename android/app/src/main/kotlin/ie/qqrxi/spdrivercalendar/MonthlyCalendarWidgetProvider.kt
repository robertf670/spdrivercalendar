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

class MonthlyCalendarWidgetProvider : AppWidgetProvider() {
    
    companion object {
        private const val PREFS_NAME = "FlutterSharedPreferences"
        private const val EVENTS_KEY = "flutter.events"
        private const val HOLIDAYS_KEY = "flutter.holidays"
        private const val START_DATE_KEY = "flutter.startDate"
        private const val START_WEEK_KEY = "flutter.startWeek"
        private const val MARKED_IN_ENABLED_KEY = "flutter.markedInEnabled"
        private const val MARKED_IN_STATUS_KEY = "flutter.markedInStatus"
        private const val BANK_HOLIDAY_DATES_KEY = "flutter.bankHolidayDates"
        private const val REST_DAY_SWAPS_KEY = "flutter.restDaySwaps"
        const val ACTION_REFRESH = "ie.qqrxi.spdrivercalendar.ACTION_REFRESH_MONTHLY"
        const val ACTION_PREV_MONTH = "ie.qqrxi.spdrivercalendar.ACTION_PREV_MONTH"
        const val ACTION_NEXT_MONTH = "ie.qqrxi.spdrivercalendar.ACTION_NEXT_MONTH"
        private const val WIDGET_MONTH_PREFIX = "widget_month_"
        private const val WIDGET_YEAR_PREFIX = "widget_year_"
        
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
        
        // Roster patterns (5-week cycle, Sunday = index 0)
        private val rosterWeeks = listOf(
            "LLRLLLR", // Week 0: Late, Late, Rest, Late, Late, Late, Rest
            "REEEERE", // Week 1: Rest, Early, Early, Early, Early, Early, Rest
            "ELLREER", // Week 2: Early, Late, Late, Rest, Early, Early, Rest
            "RRLLLLL", // Week 3: Rest, Rest, Late, Late, Late, Late, Late
            "REEEREM"  // Week 4: Rest, Early, Early, Early, Rest, Early, Middle/Relief
        )
        
        // Update widget
        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int,
            displayMonth: Int? = null,
            displayYear: Int? = null
        ) {
            var views: RemoteViews? = null
            
            // Get context with dark mode if dark mode is enabled (declare outside try block)
            val isDarkMode = isDarkModeEnabled(context)
            val colorContext = if (isDarkMode) {
                // Always create a dark context when dark mode is enabled (system or app)
                // This ensures we get dark colors consistently
                val config = Configuration(context.resources.configuration)
                config.uiMode = (config.uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or Configuration.UI_MODE_NIGHT_YES
                context.createConfigurationContext(config)
            } else {
                context
            }
            
            try {
                views = RemoteViews(context.packageName, R.layout.monthly_calendar_widget)
                
                // Apply dark mode colors if dark mode is enabled
                if (isDarkMode) {
                    // Set header text colors using dark context
                    views.setTextColor(R.id.widget_month_year, colorContext.getColor(R.color.widget_header_text))
                    views.setTextColor(R.id.widget_prev_month, colorContext.getColor(R.color.widget_header_text))
                    views.setTextColor(R.id.widget_next_month, colorContext.getColor(R.color.widget_header_text))
                    views.setTextColor(R.id.widget_refresh_button, colorContext.getColor(R.color.widget_header_text))
                    
                    // Set background colors using setInt with setBackgroundColor
                    views.setInt(R.id.widget_root, "setBackgroundColor", colorContext.getColor(R.color.widget_background))
                    // Note: Header background is set via RelativeLayout background attribute in XML
                    // We can't easily change it programmatically, but it should use dark colors automatically
                }
                
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val calendar = Calendar.getInstance()
                
                // Get or set the displayed month/year for this widget instance
                val monthKey = "$WIDGET_MONTH_PREFIX$appWidgetId"
                val yearKey = "$WIDGET_YEAR_PREFIX$appWidgetId"
                
                val currentMonth = displayMonth ?: prefs.getInt(monthKey, calendar.get(Calendar.MONTH))
                val currentYear = displayYear ?: prefs.getInt(yearKey, calendar.get(Calendar.YEAR))
                
                // Save the displayed month/year for this widget
                prefs.edit().putInt(monthKey, currentMonth).putInt(yearKey, currentYear).apply()
                
                // Set month/year header first
                try {
                    val monthYearFormat = SimpleDateFormat("MMMM yyyy", Locale.getDefault())
                    val displayCalendar = Calendar.getInstance()
                    displayCalendar.set(currentYear, currentMonth, 1)
                    views.setTextViewText(R.id.widget_month_year, monthYearFormat.format(displayCalendar.time))
                } catch (e: Exception) {
                    views.setTextViewText(R.id.widget_month_year, "Calendar")
                }
                
                // Get roster settings
                val startDateStr = prefs.getString(START_DATE_KEY, null) ?: prefs.getString("startDate", null)
                
                // Get events
                val eventsJson = prefs.getString(EVENTS_KEY, null) ?: prefs.getString("events", null)
                
                // Handle startWeek - might be stored as Int or Long
                val startWeek = try {
                    val weekValue = prefs.getAll()[START_WEEK_KEY] ?: prefs.getAll()["startWeek"]
                    when (weekValue) {
                        is Int -> weekValue
                        is Long -> weekValue.toInt()
                        else -> {
                            val intValue = prefs.getInt(START_WEEK_KEY, -1)
                            if (intValue == -1) prefs.getInt("startWeek", 0) else intValue
                        }
                    }
                } catch (e: Exception) {
                    prefs.getInt("startWeek", 0)
                }
                
                val eventsMap = parseEvents(eventsJson)
                
                // Get holidays
                val holidaysJson = prefs.getString(HOLIDAYS_KEY, null) ?: prefs.getString("holidays", null)
                val holidays = parseHolidays(holidaysJson)
                
                // Get marked-in settings (M-F shift pattern)
                val markedInEnabled = prefs.getBoolean(MARKED_IN_ENABLED_KEY, false)
                val markedInStatus = prefs.getString(MARKED_IN_STATUS_KEY, "") ?: ""
                val isMFMarkedIn = markedInEnabled && markedInStatus == "M-F"
                
                // Get bank holiday dates (for M-F: bank holidays = Rest, matches calendar)
                val bankHolidayDates = loadBankHolidayDates(context, prefs)
                val restDaySwaps = loadRestDaySwaps(prefs)
                
                // Calculate and display calendar grid
                displayCalendar(views, context, colorContext, currentYear, currentMonth, startDateStr, startWeek, eventsMap, holidays, isMFMarkedIn, bankHolidayDates, restDaySwaps)
                
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
                val refreshIntent = android.content.Intent(context, MonthlyCalendarWidgetProvider::class.java).apply {
                    action = ACTION_REFRESH
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                val refreshPendingIntent = android.app.PendingIntent.getBroadcast(
                    context,
                    appWidgetId + 1000, // Different request code from today's widget
                    refreshIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_refresh_button, refreshPendingIntent)
                
                // Set up previous month button
                val prevIntent = android.content.Intent(context, MonthlyCalendarWidgetProvider::class.java).apply {
                    action = ACTION_PREV_MONTH
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                val prevPendingIntent = android.app.PendingIntent.getBroadcast(
                    context,
                    appWidgetId + 2000,
                    prevIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_prev_month, prevPendingIntent)
                
                // Set up next month button
                val nextIntent = android.content.Intent(context, MonthlyCalendarWidgetProvider::class.java).apply {
                    action = ACTION_NEXT_MONTH
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                }
                val nextPendingIntent = android.app.PendingIntent.getBroadcast(
                    context,
                    appWidgetId + 3000,
                    nextIntent,
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_next_month, nextPendingIntent)
                
                // Update the widget
                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Exception) {
                e.printStackTrace()
                // Try to show error message
                try {
                    val errorViews = RemoteViews(context.packageName, R.layout.monthly_calendar_widget)
                    errorViews.setTextViewText(R.id.widget_month_year, "Error: ${e.message?.take(20) ?: "Unknown"}")
                    appWidgetManager.updateAppWidget(appWidgetId, errorViews)
                } catch (e2: Exception) {
                    e2.printStackTrace()
                }
            }
        }
        
        private fun loadRestDaySwaps(prefs: SharedPreferences): Map<String, String> {
            val json = prefs.getString(REST_DAY_SWAPS_KEY, null) ?: prefs.getString("restDaySwaps", null) ?: return emptyMap()
            if (json.isEmpty()) return emptyMap()
            return try {
                val array = JSONArray(json)
                val map = mutableMapOf<String, String>()
                for (i in 0 until array.length()) {
                    val obj = array.getJSONObject(i)
                    val workDate = obj.optString("workDate", "")
                    val restDate = obj.optString("restDate", "")
                    val shiftType = obj.optString("shiftType", "L")
                    if (workDate.isNotEmpty()) map[workDate] = "Rˢ"  // Swapped rest indicator
                    if (restDate.isNotEmpty()) map[restDate] = "${shiftType}ˢ"  // Swapped work indicator
                }
                map
            } catch (e: Exception) { emptyMap() }
        }
        
        private fun displayCalendar(
            views: RemoteViews,
            context: Context,
            colorContext: Context,
            year: Int,
            month: Int,
            startDateStr: String?,
            startWeek: Int,
            eventsMap: Map<String, List<EventInfo>>,
            holidays: List<HolidayInfo>,
            isMFMarkedIn: Boolean = false,
            bankHolidayDates: Set<String> = emptySet(),
            restDaySwaps: Map<String, String> = emptyMap()
        ) {
            try {
                val calendar = Calendar.getInstance()
                calendar.set(year, month, 1)
                
                // Get first day of month and number of days
                val firstDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK) // 1=Sunday, 7=Saturday
                val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
                
                // Convert to Sunday=0 format
                val firstDaySunday = (firstDayOfWeek + 6) % 7 // Convert: 1=Sun -> 0, 2=Mon -> 1, etc.
                
                // Calculate previous month's last days
                val prevMonth = if (month == 0) 11 else month - 1
                val prevYear = if (month == 0) year - 1 else year
                val prevMonthCalendar = Calendar.getInstance()
                prevMonthCalendar.set(prevYear, prevMonth, 1)
                val daysInPrevMonth = prevMonthCalendar.getActualMaximum(Calendar.DAY_OF_MONTH)
                
                // Calculate next month's first days
                val nextMonth = if (month == 11) 0 else month + 1
                val nextYear = if (month == 11) year + 1 else year
                
                // Day labels (Sun-Sat)
                val dayLabels = arrayOf("S", "M", "T", "W", "T", "F", "S")
                for (i in dayLabels.indices) {
                    try {
                        val labelId = context.resources.getIdentifier("day_label_$i", "id", context.packageName)
                        if (labelId != 0) {
                            views.setTextViewText(labelId, dayLabels[i])
                        }
                    } catch (e: Exception) {
                        // Skip if ID doesn't exist
                    }
                }
                
                // Fill calendar days (42 cells for 6 weeks)
                var currentDay = 1
                val today = Calendar.getInstance()
                val isCurrentMonth = today.get(Calendar.YEAR) == year && today.get(Calendar.MONTH) == month
                
                // Use getIdentifier for dynamic IDs - Single TextView per cell (day + pattern combined)
                for (cell in 0 until 42) {
                    try {
                        val dayId = context.resources.getIdentifier("day_$cell", "id", context.packageName)
                        if (dayId == 0) continue
                        
                        var displayDate: Calendar? = null
                        var isPrevMonth = false
                        var isNextMonth = false
                        var displayDay = 0
                        
                        if (cell < firstDaySunday) {
                            // Previous month's days
                            displayDay = daysInPrevMonth - firstDaySunday + cell + 1
                            displayDate = Calendar.getInstance()
                            displayDate.set(prevYear, prevMonth, displayDay)
                            isPrevMonth = true
                        } else if (currentDay > daysInMonth) {
                            // Next month's days
                            displayDay = currentDay - daysInMonth
                            displayDate = Calendar.getInstance()
                            displayDate.set(nextYear, nextMonth, displayDay)
                            isNextMonth = true
                            currentDay++
                        } else {
                            // Current month's days
                            displayDay = currentDay
                            displayDate = Calendar.getInstance()
                            displayDate.set(year, month, displayDay)
                            currentDay++
                        }
                        
                        if (displayDate != null) {
                            // Get roster pattern, event status, and holiday status
                            val dateKey = formatDateKey(displayDate.time)
                            val pattern = getRosterPattern(displayDate.time, startDateStr, startWeek, isMFMarkedIn, bankHolidayDates, restDaySwaps)
                            val hasEvent = eventsMap.containsKey(dateKey)
                            val holidayType = getHolidayTypeForDate(displayDate.time, holidays)
                            
                            // Build display text
                            val displayText = buildDayText(displayDay, pattern, hasEvent, holidayType)
                            
                            views.setTextViewText(dayId, displayText)
                            views.setViewVisibility(dayId, android.view.View.VISIBLE)
                            
                            // Check if this is today
                            val isToday = displayDate.get(Calendar.YEAR) == today.get(Calendar.YEAR) &&
                                         displayDate.get(Calendar.MONTH) == today.get(Calendar.MONTH) &&
                                         displayDate.get(Calendar.DAY_OF_MONTH) == today.get(Calendar.DAY_OF_MONTH)
                            
                            // Set color - dim previous/next month days, highlight today
                            if (isToday) {
                                views.setTextColor(dayId, colorContext.getColor(R.color.widget_text_accent))
                            } else if (isPrevMonth || isNextMonth) {
                                // More transparent/dimmed color for adjacent months
                                views.setTextColor(dayId, colorContext.getColor(R.color.widget_text_dimmed))
                            } else {
                                // Set color - rest day (including swapped Rˢ), then holiday, then pattern
                                val color = when {
                                    pattern == "R" || pattern == "Rˢ" -> R.color.widget_text_rest
                                    holidayType != null -> when (holidayType) {
                                        "unpaid_leave" -> android.R.color.holo_purple
                                        "day_in_lieu" -> android.R.color.holo_blue_dark
                                        else -> android.R.color.holo_blue_light
                                    }
                                    else -> when {
                                        pattern.startsWith("E") || pattern.startsWith("W") -> R.color.widget_text_accent
                                        pattern.startsWith("L") -> android.R.color.holo_orange_dark
                                        pattern.startsWith("M") -> android.R.color.holo_purple
                                        else -> R.color.widget_text_primary
                                    }
                                }
                                views.setTextColor(dayId, colorContext.getColor(color))
                            }
                        } else {
                            // Empty cell (shouldn't happen with 42 cells)
                            views.setTextViewText(dayId, "")
                            views.setViewVisibility(dayId, android.view.View.INVISIBLE)
                        }
                    } catch (e: Exception) {
                        // Skip this cell if there's an error
                        e.printStackTrace()
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
        
        private fun loadBankHolidayDates(context: Context, prefs: SharedPreferences): Set<String> {
            // Try SharedPreferences first (persisted by Flutter app at startup)
            var json = prefs.getString(BANK_HOLIDAY_DATES_KEY, null)
            if (json.isNullOrEmpty()) json = prefs.getString("bankHolidayDates", null)
            var dates = parseBankHolidayDates(json)
            // Fallback: load from assets if prefs empty (e.g. widget shown before app opened)
            if (dates.isEmpty()) {
                dates = loadBankHolidaysFromAssets(context)
            }
            return dates
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
            // Fallback: extract yyyy-MM-dd if string contains T
            val datePart = if (dateStr.contains("T")) dateStr.split("T")[0] else dateStr
            return try { SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(datePart) } catch (_: Exception) { null }
        }
        
        private fun parseBankHolidayDates(json: String?): Set<String> {
            if (json == null || json.isEmpty()) return emptySet()
            return try {
                val array = JSONArray(json)
                (0 until array.length()).map { array.getString(it) }.toSet()
            } catch (e: Exception) { emptySet() }
        }
        
        private fun loadBankHolidaysFromAssets(context: Context): Set<String> {
            val pathsToTry = listOf("flutter_assets/assets/bank_holidays.json", "assets/bank_holidays.json")
            for (path in pathsToTry) {
                try {
                    val dates = context.assets.open(path).bufferedReader().use { reader ->
                        val content = reader.readText()
                        val root = JSONObject(content)
                        val yearsArray = root.getJSONArray("IrelandBankHolidays")
                        val set = mutableSetOf<String>()
                        for (i in 0 until yearsArray.length()) {
                            val yearObj = yearsArray.getJSONObject(i)
                            val holidaysArray = yearObj.getJSONArray("holidays")
                            for (j in 0 until holidaysArray.length()) {
                                val holiday = holidaysArray.getJSONObject(j)
                                val dateStr = holiday.optString("date", "")
                                if (dateStr.isNotEmpty()) set.add(dateStr)
                            }
                        }
                        set
                    }
                    if (dates.isNotEmpty()) return dates
                } catch (e: Exception) { /* try next path */ }
            }
            return emptySet()
        }
        
        private fun getRosterPattern(date: Date, startDateStr: String?, startWeek: Int, isMFMarkedIn: Boolean = false, bankHolidayDates: Set<String> = emptySet(), restDaySwaps: Map<String, String> = emptyMap()): String? {
            val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date)
            restDaySwaps[dateKey]?.let { return it }
            
            val calendar = Calendar.getInstance()
            calendar.time = date
            
            // M-F marked in: W on Mon-Fri, R on Sat-Sun, R on bank holidays (matches calendar exactly)
            if (isMFMarkedIn) {
                val dateKey = SimpleDateFormat("yyyy-MM-dd", Locale.US).format(date)
                if (bankHolidayDates.contains(dateKey)) return "R"  // Bank holiday = Rest
                val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
                return if (dayOfWeek >= Calendar.MONDAY && dayOfWeek <= Calendar.FRIDAY) "W" else "R"
            }
            
            if (startDateStr == null) return null
            
            try {
                val startDate = SimpleDateFormat("yyyy-MM-dd", Locale.US).parse(startDateStr)
                    ?: return null
                
                val dayOfWeek = calendar.get(Calendar.DAY_OF_WEEK) // 1=Sunday, 7=Saturday
                val dayIndex = (dayOfWeek + 6) % 7 // Convert to 0=Sunday
                
                val startCal = Calendar.getInstance()
                startCal.time = startDate
                
                val daysSinceStart = ((calendar.timeInMillis - startCal.timeInMillis) / (1000 * 60 * 60 * 24)).toInt()
                
                // Calculate week number in 5-week cycle
                val weeksSinceStart = daysSinceStart / 7
                val weekNumber = (startWeek + weeksSinceStart) % 5
                if (weekNumber < 0) {
                    val adjustedWeek = (weekNumber + 5) % 5
                    val pattern = rosterWeeks[adjustedWeek]
                    return pattern[dayIndex].toString()
                }
                
                val pattern = rosterWeeks[weekNumber]
                return pattern[dayIndex].toString()
            } catch (e: Exception) {
                return null
            }
        }
        
        private fun parseEvents(eventsJson: String?): Map<String, List<EventInfo>> {
            val eventsMap = mutableMapOf<String, List<EventInfo>>()
            
            if (eventsJson == null || eventsJson.isEmpty()) return eventsMap
            
            try {
                val jsonObject = JSONObject(eventsJson)
                val keys = jsonObject.keys()
                
                while (keys.hasNext()) {
                    val key = keys.next()
                    val dateKey = if (key.contains("T")) key.split("T")[0] else key
                    
                    val eventsArray = jsonObject.optJSONArray(key) ?: continue
                    val events = mutableListOf<EventInfo>()
                    
                    for (i in 0 until eventsArray.length()) {
                        val eventObj = eventsArray.getJSONObject(i)
                        val title = eventObj.optString("title", "")
                        
                        if (isWorkShift(title)) {
                            events.add(EventInfo(title))
                        }
                    }
                    
                    if (events.isNotEmpty()) {
                        eventsMap[dateKey] = events
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            
            return eventsMap
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
        
        private fun formatDateKey(date: Date): String {
            val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
            return sdf.format(date)
        }
        
        private fun buildDayText(day: Int, pattern: String?, hasEvent: Boolean, holidayType: String?): String {
            val eventMarker = if (hasEvent) " •" else ""
            return when {
                pattern == "R" || pattern == "Rˢ" -> "$day\n${pattern ?: "R"}$eventMarker"
                holidayType != null -> {
                    val marker = when (holidayType) {
                        "unpaid_leave" -> "UL"
                        "day_in_lieu" -> "DIL"
                        else -> "H"
                    }
                    "$day\n$marker$eventMarker"
                }
                pattern != null -> "$day\n$pattern$eventMarker"
                else -> "$day$eventMarker"
            }
        }
        
        private fun parseHolidays(holidaysJson: String?): List<HolidayInfo> {
            val holidays = mutableListOf<HolidayInfo>()
            
            if (holidaysJson == null || holidaysJson.isEmpty()) return holidays
            
            try {
                val jsonArray = JSONArray(holidaysJson)
                for (i in 0 until jsonArray.length()) {
                    val holidayObj = jsonArray.getJSONObject(i)
                    val startDateStr = holidayObj.optString("startDate", "")
                    val endDateStr = holidayObj.optString("endDate", "")
                    val type = holidayObj.optString("type", "other")
                    
                    if (startDateStr.isNotEmpty() && endDateStr.isNotEmpty()) {
                        try {
                            // Dart toIso8601String() produces "yyyy-MM-ddTHH:mm:ss.mmm" - try formats in order
                            val startDate = parseHolidayDate(startDateStr)
                            val endDate = parseHolidayDate(endDateStr)
                            
                            if (startDate != null && endDate != null) {
                                holidays.add(HolidayInfo(startDate, endDate, type))
                            }
                        } catch (e: Exception) {
                            // Skip invalid date format
                            e.printStackTrace()
                        }
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            
            return holidays
        }
        
        private fun getHolidayTypeForDate(date: Date, holidays: List<HolidayInfo>): String? {
            val calendar = Calendar.getInstance()
            calendar.time = date
            val year = calendar.get(Calendar.YEAR)
            val month = calendar.get(Calendar.MONTH)
            val day = calendar.get(Calendar.DAY_OF_MONTH)
            
            for (holiday in holidays) {
                val holidayStart = Calendar.getInstance()
                holidayStart.time = holiday.startDate
                val holidayEnd = Calendar.getInstance()
                holidayEnd.time = holiday.endDate
                
                // Normalize dates to midnight for comparison
                val checkDate = Calendar.getInstance()
                checkDate.set(year, month, day, 0, 0, 0)
                checkDate.set(Calendar.MILLISECOND, 0)
                
                val startDate = Calendar.getInstance()
                startDate.set(holidayStart.get(Calendar.YEAR), holidayStart.get(Calendar.MONTH), 
                              holidayStart.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
                startDate.set(Calendar.MILLISECOND, 0)
                
                val endDate = Calendar.getInstance()
                endDate.set(holidayEnd.get(Calendar.YEAR), holidayEnd.get(Calendar.MONTH), 
                           holidayEnd.get(Calendar.DAY_OF_MONTH), 0, 0, 0)
                endDate.set(Calendar.MILLISECOND, 0)
                
                if (!checkDate.before(startDate) && !checkDate.after(endDate)) {
                    return holiday.type
                }
            }
            
            return null
        }
        
        private fun isDateInHoliday(date: Date, holidays: List<HolidayInfo>): Boolean {
            return getHolidayTypeForDate(date, holidays) != null
        }
        
        private fun buildSimpleCalendarText(
            year: Int,
            month: Int,
            startDateStr: String?,
            startWeek: Int,
            eventsMap: Map<String, List<EventInfo>>
        ): String {
            try {
                val calendar = Calendar.getInstance()
                calendar.set(year, month, 1)
                val daysInMonth = calendar.getActualMaximum(Calendar.DAY_OF_MONTH)
                val firstDayOfWeek = calendar.get(Calendar.DAY_OF_WEEK)
                val firstDaySunday = (firstDayOfWeek + 6) % 7
                
                val sb = StringBuilder()
                sb.append("S M T W T F S\n")
                
                // Add spacing for first day
                for (i in 0 until firstDaySunday) {
                    sb.append("  ")
                }
                
                // Add days
                for (day in 1..daysInMonth) {
                    val date = Calendar.getInstance()
                    date.set(year, month, day)
                    val pattern = getRosterPattern(date.time, startDateStr, startWeek)
                    val hasEvent = eventsMap.containsKey(formatDateKey(date.time))
                    
                    val dayStr = if (day < 10) " $day" else "$day"
                    val displayStr = when {
                        pattern != null -> "$dayStr$pattern"
                        hasEvent -> "${dayStr}*"
                        else -> dayStr
                    }
                    sb.append(displayStr)
                    
                    if ((firstDaySunday + day) % 7 == 0) {
                        sb.append("\n")
                    } else {
                        sb.append(" ")
                    }
                }
                
                return sb.toString()
            } catch (e: Exception) {
                return "Error building calendar"
            }
        }
    }
    
    override fun onReceive(context: Context, intent: android.content.Intent) {
        super.onReceive(context, intent)
        
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val appWidgetId = intent.getIntExtra(
            AppWidgetManager.EXTRA_APPWIDGET_ID,
            AppWidgetManager.INVALID_APPWIDGET_ID
        )
        
        if (appWidgetId == AppWidgetManager.INVALID_APPWIDGET_ID) return
        
        when (intent.action) {
            ACTION_REFRESH -> {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
            ACTION_PREV_MONTH -> {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val monthKey = "$WIDGET_MONTH_PREFIX$appWidgetId"
                val yearKey = "$WIDGET_YEAR_PREFIX$appWidgetId"
                val currentMonth = prefs.getInt(monthKey, Calendar.getInstance().get(Calendar.MONTH))
                val currentYear = prefs.getInt(yearKey, Calendar.getInstance().get(Calendar.YEAR))
                
                val calendar = Calendar.getInstance()
                calendar.set(currentYear, currentMonth, 1)
                calendar.add(Calendar.MONTH, -1)
                
                updateAppWidget(context, appWidgetManager, appWidgetId, calendar.get(Calendar.MONTH), calendar.get(Calendar.YEAR))
            }
            ACTION_NEXT_MONTH -> {
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val monthKey = "$WIDGET_MONTH_PREFIX$appWidgetId"
                val yearKey = "$WIDGET_YEAR_PREFIX$appWidgetId"
                val currentMonth = prefs.getInt(monthKey, Calendar.getInstance().get(Calendar.MONTH))
                val currentYear = prefs.getInt(yearKey, Calendar.getInstance().get(Calendar.YEAR))
                
                val calendar = Calendar.getInstance()
                calendar.set(currentYear, currentMonth, 1)
                calendar.add(Calendar.MONTH, 1)
                
                updateAppWidget(context, appWidgetManager, appWidgetId, calendar.get(Calendar.MONTH), calendar.get(Calendar.YEAR))
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

// Data class for event info
data class EventInfo(val title: String)

// Data class for holiday info
data class HolidayInfo(val startDate: Date, val endDate: Date, val type: String = "other")

