package com.focusmate.ai.focusmate_ai

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.view.accessibility.AccessibilityEvent
import android.content.Intent
import io.flutter.plugin.common.EventChannel

class AppAccessibilityService : AccessibilityService() {

    companion object {
        private var eventSink: EventChannel.EventSink? = null

        fun setEventSink(sink: EventChannel.EventSink?) {
            eventSink = sink
        }
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val packageName = event.packageName?.toString() ?: return
        
        val isTrackedApp = packageName.contains("youtube") || 
                           packageName.contains("instagram") || 
                           packageName.contains("facebook") || 
                           packageName.contains("whatsapp")

        // Capture window changes and content updates to track metadata
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED || 
            (event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED && isTrackedApp)) {
            
            val contentMetadata = try {
                extractSignificantText(rootInActiveWindow)
            } catch (e: Exception) {
                ""
            }
            
            val data = mapOf(
                "packageName" to packageName,
                "content" to contentMetadata
            )
            
            eventSink?.success(data)
        }
    }

    private fun extractSignificantText(node: android.view.accessibility.AccessibilityNodeInfo?): String {
        if (node == null) return ""
        val sb = StringBuilder()
        findText(node, sb, 0)
        return sb.toString().trim()
    }

    private fun findText(node: android.view.accessibility.AccessibilityNodeInfo, sb: StringBuilder, depth: Int) {
        // Limit depth to avoid performance issues
        if (depth > 50) return 
        
        val text = node.text?.toString()
        if (!text.isNullOrBlank() && text.length > 15) {
            // In YouTube, the video title is usually a long text node
            sb.append(text).append(" ")
            return // Often the title doesn't have relevant sub-nodes we need for focus tracking
        }
        
        for (i in 0 until node.childCount) {
            val child = node.getChild(i)
            if (child != null) {
                findText(child, sb, depth + 1)
            }
        }
    }

    override fun onInterrupt() {}

    override fun onServiceConnected() {
        super.onServiceConnected()
        val info = AccessibilityServiceInfo()
        // Listen for both window switches and content changes inside apps
        info.eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED or 
                         AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED
        info.feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
        info.flags = AccessibilityServiceInfo.FLAG_RETRIEVE_INTERACTIVE_WINDOWS or 
                    AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
        info.notificationTimeout = 500 // Don't spam events too fast
        this.serviceInfo = info
    }
}
