package com.example.antimatter

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

class TasksWidgetReceiver : AppWidgetProvider() {

    companion object {
        const val ACTION_COMPLETE_TASK = "com.example.antimatter.ACTION_COMPLETE_TASK"
        const val EXTRA_TASK_ID = "extra_task_id"
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_COMPLETE_TASK) {
            val taskId = intent.getStringExtra(EXTRA_TASK_ID) ?: return
            handleTaskCompletion(context, taskId)
            return
        }
        if (intent.action == "es.antonborri.home_widget.action.UPDATE") {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val widgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, TasksWidgetReceiver::class.java)
            )
            for (id in widgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
        super.onReceive(context, intent)
    }

    private fun handleTaskCompletion(context: Context, taskId: String) {
        val widgetData = HomeWidgetPlugin.getData(context)

        // 1. Remove the task from the active tasks list
        val tasksJson = widgetData.getString("active_tasks", "[]")
        val tasksArray = try { JSONArray(tasksJson) } catch (_: Exception) { JSONArray() }

        val updatedArray = JSONArray()
        for (i in 0 until tasksArray.length()) {
            val obj = tasksArray.optJSONObject(i) ?: continue
            if (obj.optString("id") != taskId) {
                updatedArray.put(obj)
            }
        }

        // 2. Save the completed task ID for Flutter to sync later
        val completedIdsJson = widgetData.getString("widget_completed_ids", "[]")
        val completedIds = try { JSONArray(completedIdsJson) } catch (_: Exception) { JSONArray() }
        completedIds.put(taskId)

        // 3. Write back to SharedPreferences
        val editor = widgetData.edit()
        editor.putString("active_tasks", updatedArray.toString())
        editor.putString("widget_completed_ids", completedIds.toString())
        editor.apply()

        // 4. Force refresh the widget
        val appWidgetManager = AppWidgetManager.getInstance(context)
        val widgetIds = appWidgetManager.getAppWidgetIds(
            ComponentName(context, TasksWidgetReceiver::class.java)
        )
        for (id in widgetIds) {
            updateAppWidget(context, appWidgetManager, id)
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

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_tasks)

        val widgetData = HomeWidgetPlugin.getData(context)
        val opacity = widgetData.getFloat("widget_opacity", 0.8f).toDouble()
        val themeMode = widgetData.getString("widget_theme", "system") ?: "system"

        val isSystemDark = (context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
        val isDark = when (themeMode) {
            "dark" -> true
            "light" -> false
            else -> isSystemDark
        }

        // Apply appearance customizations dynamically
        val bgColor = if (isDark) Color.parseColor("#121212") else Color.parseColor("#F5F5F5")
        val textColor = if (isDark) Color.parseColor("#E6E6E6") else Color.parseColor("#1C1C1C")
        val emptyTextColor = if (isDark) Color.parseColor("#A0A0A0") else Color.parseColor("#757575")

        // Set dynamic tint on the white background shape
        views.setInt(R.id.widget_dynamic_bg, "setColorFilter", bgColor)
        // Set dynamic alpha on the background image (0..255)
        views.setInt(R.id.widget_dynamic_bg, "setImageAlpha", (opacity * 255).toInt())

        views.setTextColor(R.id.widget_title, textColor)
        views.setTextColor(R.id.widget_empty_view, emptyTextColor)

        // Setup the list adapter
        val serviceIntent = Intent(context, TasksWidgetService::class.java).apply {
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
        }
        views.setRemoteAdapter(R.id.widget_task_list, serviceIntent)
        views.setEmptyView(R.id.widget_task_list, R.id.widget_empty_view)

        // PendingIntent template for checkbox clicks (broadcasts to this receiver)
        val checkboxTemplate = Intent(context, TasksWidgetReceiver::class.java).apply {
            action = ACTION_COMPLETE_TASK
        }
        val checkboxPendingIntent = PendingIntent.getBroadcast(
            context,
            0,
            checkboxTemplate,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
        views.setPendingIntentTemplate(R.id.widget_task_list, checkboxPendingIntent)

        // Click on title/empty view launches the app
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val launchPending = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        views.setOnClickPendingIntent(R.id.widget_title, launchPending)
        views.setOnClickPendingIntent(R.id.widget_empty_view, launchPending)

        appWidgetManager.updateAppWidget(appWidgetId, views)
        appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_task_list)
    }
}
