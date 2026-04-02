package com.example.antimatter

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray
import org.json.JSONException

class TasksWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return TasksRemoteViewsFactory(this.applicationContext)
    }
}

class TasksRemoteViewsFactory(private val context: Context) : RemoteViewsService.RemoteViewsFactory {
    
    private var tasksArray = JSONArray()

    override fun onCreate() {
        loadData()
    }

    override fun onDataSetChanged() {
        loadData()
    }

    override fun onDestroy() {
        tasksArray = JSONArray()
    }

    override fun getCount(): Int {
        return tasksArray.length()
    }

    private fun loadData() {
        val widgetData = HomeWidgetPlugin.getData(context)
        val tasksString = widgetData.getString("active_tasks", "[]")
        try {
            tasksArray = JSONArray(tasksString)
        } catch (e: JSONException) {
            e.printStackTrace()
            tasksArray = JSONArray()
        }
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_task_item)
        
        try {
            val taskObj = tasksArray.getJSONObject(position)
            val id = taskObj.optString("id", "")
            val title = taskObj.optString("title", "")
            views.setTextViewText(R.id.task_title, title)
            
            // Fill-in intent for checkbox container
            // This merges with the PendingIntentTemplate set in the receiver
            val fillInIntent = Intent().apply {
                putExtra(TasksWidgetReceiver.EXTRA_TASK_ID, id)
            }
            views.setOnClickFillInIntent(R.id.task_checkbox_container, fillInIntent)
            
        } catch (e: JSONException) {
            e.printStackTrace()
        }

        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
}
