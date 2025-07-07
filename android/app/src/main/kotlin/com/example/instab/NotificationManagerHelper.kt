package com.example.instab

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat

class NotificationManagerHelper(private val context: Context) {
    private val TAG = "NotificationManagerHelper"
    private val CHANNEL_ID = "app_monitor_service"
    private val NOTIFICATION_ID = 1001
    
    fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Alertes Social Media",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Alertes critiques pour Instagram et TikTok"
                enableVibration(true)
                enableLights(true)
                lightColor = android.graphics.Color.RED
                setBypassDnd(true)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
                vibrationPattern = longArrayOf(0, 1000, 500, 1000)
                setSound(
                    android.provider.Settings.System.DEFAULT_NOTIFICATION_URI, 
                    android.app.Notification.AUDIO_ATTRIBUTES_DEFAULT
                )
            }
            
            val notificationManager = context.getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
            Log.d(TAG, "🔔 Canal de notification créé")
        }
    }
    
    fun createServiceNotification(): Notification {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_menu_view)
            .setContentTitle("🔍 Social Media Monitor")
            .setContentText("👁️ En surveillance")
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }
    
    fun sendServiceStartedNotification() {
        val title = "✅ Service démarré"
        val message = "Le service de surveillance est maintenant actif et détectera Instagram et TikTok."
        
        val notificationId = 1234
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
        val pendingIntent = PendingIntent.getActivity(
            context, notificationId, intent, PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, builder.build())
        
        Log.d(TAG, "📣 Notification de démarrage envoyée")
    }
    
    fun sendImmediateWarning(appName: String) {
        val title = "⚠️ ATTENTION - $appName"
        val message = "Tu es sûr(e) de vouloir aller sur $appName maintenant ?"
        
        Log.d(TAG, "📣 Envoi notification immédiate pour $appName")
        sendHighPriorityNotification(title, message, generateNotificationId())
    }
    
    fun sendTimeWarning(appName: String, timeSpent: Long) {
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
        
        Log.d(TAG, "📣 Notification temps pour $appName: ${timeSpent}s")
        sendHighPriorityNotification(title, message, generateNotificationId())
    }
    
    fun sendPermissionErrorNotification() {
        val title = "⚠️ PERMISSION MANQUANTE"
        val message = "L'accès aux données d'utilisation est requis. Cliquez pour l'activer."
        
        val intent = Intent(context, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            context, 0, intent, PendingIntent.FLAG_IMMUTABLE
        )
        
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(android.R.drawable.ic_dialog_alert)
            .setContentTitle(title)
            .setContentText(message)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setContentIntent(pendingIntent)
            .setAutoCancel(true)
        
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(9998, builder.build())
    }
    
    private fun sendHighPriorityNotification(title: String, message: String, id: Int) {
        try {
            val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            val pendingIntent = PendingIntent.getActivity(
                context, id, intent, PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT
            )
            
            val builder = NotificationCompat.Builder(context, CHANNEL_ID)
                .setSmallIcon(android.R.drawable.ic_dialog_alert)
                .setContentTitle(title)
                .setContentText(message)
                .setStyle(NotificationCompat.BigTextStyle().bigText(message))
                .setPriority(NotificationCompat.PRIORITY_MAX)
                .setCategory(NotificationCompat.CATEGORY_ALARM)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .setVibrate(longArrayOf(0, 1000, 500, 1000))
                .setLights(android.graphics.Color.RED, 3000, 3000)
                .setSound(android.provider.Settings.System.DEFAULT_NOTIFICATION_URI)
                .setAutoCancel(true)
                .setContentIntent(pendingIntent)
                .setOngoing(true)
                .setFullScreenIntent(pendingIntent, true)

            val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.cancel(id)
            notificationManager.notify(id, builder.build())
            
            Log.d(TAG, "🚨 NOTIFICATION FORCÉE ENVOYÉE: $title (ID: $id)")
            
            Thread.sleep(500)
            
        } catch (e: Exception) {
            Log.e(TAG, "❌ ERREUR lors de l'envoi de notification forcée", e)
        }
    }
    
    fun forceSendInstagramNotification() {
        Log.d(TAG, "🚨 FORÇAGE NOTIFICATION INSTAGRAM")
        val title = "⚠️ ATTENTION - Instagram"
        val message = "Tu es sûr(e) de vouloir aller sur Instagram maintenant ?"
        sendHighPriorityNotification(title, message, 8888)
    }
    
    fun forceSendTikTokNotification() {
        Log.d(TAG, "🚨 FORÇAGE NOTIFICATION TIKTOK")
        val title = "⚠️ ATTENTION - TikTok"
        val message = "Tu es sûr(e) de vouloir aller sur TikTok maintenant ?"
        sendHighPriorityNotification(title, message, 9999)
    }
    
    fun updateServiceNotification() {
        val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(NOTIFICATION_ID, createServiceNotification())
    }
    
    private fun generateNotificationId(): Int {
        return (2000..9999).random()
    }
}