package com.example.instab

import android.app.*
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat
import java.util.*
import kotlin.concurrent.timer

class AppMonitorService : Service() {
    private val TAG = "AppMonitorService"
    private val CHANNEL_ID = "app_monitor_service"
    private val NOTIFICATION_ID = 1001
    
    private val socialApps = mapOf(
        "com.instagram.android" to "Instagram",
        "com.zhiliaoapp.musically" to "TikTok",
        "com.ss.android.ugc.trill" to "TikTok"
    )
    
    private var wakeLock: PowerManager.WakeLock? = null
    private var monitoringTimer: Timer? = null
    private var currentSocialApp: String? = null
    private var startTime: Long = 0
    private var lastNotificationTime: Long = 0
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service created")
        
        createNotificationChannel()
        startForeground(NOTIFICATION_ID, createServiceNotification())
        
        // Wake lock pour maintenir le service actif
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK,
            "instab:AppMonitorWakeLock"
        )
        wakeLock?.acquire()
        
        startMonitoring()
    }
    
    private fun startMonitoring() {
        monitoringTimer = timer("AppMonitor", true, 0, 1000) {
            checkCurrentApp()
        }
    }
    
    private fun checkCurrentApp() {
        try {
            val currentApp = getCurrentForegroundApp()
            val currentTime = System.currentTimeMillis()
            
            if (currentApp != null && socialApps.containsKey(currentApp)) {
                val appName = socialApps[currentApp]!!
                
                if (currentSocialApp != currentApp) {
                    // Nouvelle app sociale détectée
                    currentSocialApp = currentApp
                    startTime = currentTime
                    lastNotificationTime = currentTime
                    
                    Log.d(TAG, "Social app detected: $appName")
                    sendImmediateWarning(appName)
                } else {
                    // Même app, vérifier le temps écoulé
                    val timeSpent = (currentTime - startTime) / 1000
                    val timeSinceLastNotif = (currentTime - lastNotificationTime) / 1000
                    
                    val notificationInterval = calculateInterval(timeSpent)
                    
                    if (timeSinceLastNotif >= notificationInterval) {
                        sendTimeWarning(appName, timeSpent)
                        lastNotificationTime = currentTime
                    }
                }
            } else if (currentSocialApp != null) {
                // Plus sur une app sociale
                Log.d(TAG, "Stopped using social app: $currentSocialApp")
                currentSocialApp = null
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error checking app", e)
        }
    }
    
    private fun getCurrentForegroundApp(): String? {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager
        if (usageStatsManager == null) {
            Log.e(TAG, "UsageStatsManager not available")
            return null
        }
        
        val endTime = System.currentTimeMillis()
        val beginTime = endTime - 5000 // 5 secondes
        
        try {
            val events = usageStatsManager.queryEvents(beginTime, endTime)
            var lastEvent: String? = null
            var lastTimestamp = 0L
            
            val event = UsageEvents.Event()
            while (events.hasNextEvent()) {
                events.getNextEvent(event)
                
                if ((event.eventType == UsageEvents.Event.ACTIVITY_RESUMED || 
                     event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) &&
                    event.timeStamp > lastTimestamp) {
                    lastEvent = event.packageName
                    lastTimestamp = event.timeStamp
                }
            }
            
            return lastEvent
        } catch (e: Exception) {
            Log.e(TAG, "Error querying usage events", e)
            return null
        }
    }
    
    private fun calculateInterval(timeSpent: Long): Long {
        return when {
            timeSpent < 60 -> 60    // Première minute: notification après 1 min
            timeSpent < 120 -> 30   // 2ème minute: toutes les 30s
            timeSpent < 180 -> 15   // 3ème minute: toutes les 15s
            timeSpent < 300 -> 10   // Jusqu'à 5 min: toutes les 10s
            timeSpent < 600 -> 5    // Jusqu'à 10 min: toutes les 5s
            else -> 2               // Après 10 min: toutes les 2s
        }
    }
    
    private fun sendImmediateWarning(appName: String) {
        val title = "⚠️ ATTENTION !"
        val message = "Tu es sûr(e) de vouloir aller sur $appName maintenant ?"
        
        sendNotification(title, message, 2000, true)
    }
    
    private fun sendTimeWarning(appName: String, timeSpent: Long) {
        val minutes = timeSpent / 60
        val seconds = timeSpent % 60
        
        val title = when {
            timeSpent < 60 -> "⏰ $appName - ${seconds}s"
            timeSpent < 300 -> "⚠️ $appName - ${minutes}min ${seconds}s"
            else -> "🚨 ARRÊTE $appName MAINTENANT !"
        }
        
        val message = when {
            timeSpent < 60 -> "Tu as déjà passé ${seconds}s sur $appName !"
            timeSpent < 180 -> "Ça fait ${minutes}min ${seconds}s sur $appName ! Arrête maintenant !"
            timeSpent < 300 -> "ATTENTION : ${minutes}min ${seconds}s sur $appName ! C'est TROP !"
            else -> "FERME $appName IMMÉDIATEMENT ! ${minutes}min ${seconds}s de perdues !"
        }
        
        val urgent = timeSpent > 120
        sendNotification(title, message, 2001, urgent)
    }
    
    private fun sendNotification(title: String, message: String, id: Int, urgent: Boolean) {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(message)
            .setStyle(NotificationCompat.BigTextStyle().bigText(message))
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(if (urgent) NotificationCompat.CATEGORY_ALARM else NotificationCompat.CATEGORY_MESSAGE)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .setVibrate(if (urgent) longArrayOf(0, 1000, 500, 1000, 500, 1000) else longArrayOf(0, 500, 200, 500))
            .setOngoing(urgent)
        
        if (urgent) {
            builder.setFullScreenIntent(pendingIntent, true)
        }
        
        val notification = builder.build()
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(id, notification)
        
        Log.d(TAG, "Notification sent: $title")
    }
    
    private fun createServiceNotification(): Notification {
        val intent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("🔍 Surveillance Instagram/TikTok")
            .setContentText("Protection active en arrière-plan")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Social Media Monitor",
                NotificationManager.IMPORTANCE_HIGH
            )
            channel.description = "Alertes critiques pour Instagram et TikTok"
            channel.enableVibration(true)
            channel.enableLights(true)
            channel.lightColor = android.graphics.Color.RED
            channel.setBypassDnd(true)
            
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service command received")
        return START_STICKY // Redémarre automatiquement si tué
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        
        monitoringTimer?.cancel()
        wakeLock?.release()
        
        // Redémarrer immédiatement le service
        val restartIntent = Intent(this, AppMonitorService::class.java)
        startService(restartIntent)
        
        Log.d(TAG, "Service destroyed, restarting...")
    }
}
