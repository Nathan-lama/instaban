package com.example.instab

import android.content.Context
import android.util.Log
import java.util.*

class AppDetector(private val context: Context) {
    private val TAG = "AppDetector"
    
    fun getCurrentForegroundApp(): String? {
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as? android.app.usage.UsageStatsManager
                ?: return null
                
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 5000  // 5 secondes
            
            // Vérifier les événements récents
            val events = usageStatsManager.queryEvents(startTime, endTime)
            var lastPackageName: String? = null
            var lastTimestamp = 0L
            
            val event = android.app.usage.UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED && 
                    event.timeStamp > lastTimestamp) {
                    lastPackageName = event.packageName
                    lastTimestamp = event.timeStamp
                }
            }
            
            if (lastPackageName != null) {
                return lastPackageName
            }
            
            return getFromUsageStats(usageStatsManager, startTime, endTime)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur lors de la détection d'app", e)
            return null
        }
    }
    
    private fun getFromUsageStats(usageStatsManager: android.app.usage.UsageStatsManager, startTime: Long, endTime: Long): String? {
        val stats = usageStatsManager.queryUsageStats(
            android.app.usage.UsageStatsManager.INTERVAL_DAILY,
            startTime,
            endTime
        )
        
        if (!stats.isNullOrEmpty()) {
            val sorted = stats.sortedByDescending { it.lastTimeUsed }
            
            // Priorité aux réseaux sociaux
            val socialApps = mapOf(
                "com.instagram.android" to "Instagram",
                "com.zhiliaoapp.musically" to "TikTok",
                "com.ss.android.ugc.trill" to "TikTok"
            )
            
            val socialMediaApp = sorted.firstOrNull { 
                socialApps.containsKey(it.packageName) && it.lastTimeUsed >= startTime
            }
            
            if (socialMediaApp != null) {
                return socialMediaApp.packageName
            }
            
            // Sinon l'app la plus récente
            val mostRecentApp = sorted.firstOrNull()
            if (mostRecentApp != null && mostRecentApp.lastTimeUsed >= startTime) {
                return mostRecentApp.packageName
            }
        }
        
        return null
    }
    
    fun simulateCheckingAllApps() {
        try {
            val instagramPackage = "com.instagram.android"
            val tiktokPackage1 = "com.zhiliaoapp.musically"
            val tiktokPackage2 = "com.ss.android.ugc.trill"
            
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 30000 // 30 secondes
            
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
            val stats = usageStatsManager.queryUsageStats(
                android.app.usage.UsageStatsManager.INTERVAL_DAILY,
                startTime, endTime
            )
            
            if (!stats.isNullOrEmpty()) {
                Log.d(TAG, "📊 Trouvé ${stats.size} apps utilisées récemment")
                
                val sorted = stats.sortedByDescending { it.lastTimeUsed }
                for (stat in sorted.take(5)) {
                    Log.d(TAG, "📱 App récente: ${stat.packageName}, dernier usage: ${Date(stat.lastTimeUsed)}")
                }
            }
            
            checkEventsExplicitly(instagramPackage, tiktokPackage1, tiktokPackage2)
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur lors de la vérification manuelle", e)
        }
    }
    
    private fun checkEventsExplicitly(instagramPackage: String, tiktokPackage1: String, tiktokPackage2: String) {
        try {
            val usageStatsManager = context.getSystemService(Context.USAGE_STATS_SERVICE) as android.app.usage.UsageStatsManager
            val endTime = System.currentTimeMillis()
            val startTime = endTime - 30000 // 30 secondes
            
            val events = usageStatsManager.queryEvents(startTime, endTime)
            val event = android.app.usage.UsageEvents.Event()
            
            var found = false
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                
                if (event.eventType == android.app.usage.UsageEvents.Event.ACTIVITY_RESUMED) {
                    Log.d(TAG, "🎯 Événement trouvé: ${event.packageName}")
                    found = true
                }
            }
            
            if (!found) {
                Log.d(TAG, "❌ Aucun événement trouvé dans la période")
            }
        } catch (e: Exception) {
            Log.e(TAG, "❌ Erreur lors de la vérification des événements", e)
        }
    }
}