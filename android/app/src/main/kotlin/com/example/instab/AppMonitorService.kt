package com.example.instab

import android.app.*
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.util.Log
import androidx.core.app.NotificationCompat

class AppMonitorService : Service() {
    private val TAG = "AppMonitorService"
    private val NOTIFICATION_ID = 1001
    
    private var wakeLock: PowerManager.WakeLock? = null
    private val handler = Handler(Looper.getMainLooper())
    private var runnable: Runnable? = null
    
    private lateinit var appDetector: AppDetector
    private lateinit var sessionManager: SessionManager
    private lateinit var notificationManager: NotificationManagerHelper
    private lateinit var permissionChecker: PermissionChecker
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "🚀🚀🚀 SERVICE DÉMARRÉ 🚀🚀🚀")
        
        // Initialiser les composants
        appDetector = AppDetector(this)
        sessionManager = SessionManager()
        notificationManager = NotificationManagerHelper(this)
        permissionChecker = PermissionChecker(this)
        
        // Configuration du service
        setupService()
        
        if (permissionChecker.checkHasUsagePermission()) {
            startMonitoring()
        } else {
            Log.e(TAG, "❌ Permission d'usage non accordée")
            notificationManager.sendPermissionErrorNotification()
        }
    }
    
    private fun setupService() {
        notificationManager.createNotificationChannel()
        startForeground(NOTIFICATION_ID, notificationManager.createServiceNotification())
        notificationManager.sendServiceStartedNotification()
        
        // Wake lock
        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = powerManager.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "instab:AppMonitorWakeLock")
        wakeLock?.acquire(24*60*60*1000L)
    }
    
    private fun startMonitoring() {
        Log.d(TAG, "🔍 Démarrage du monitoring")
        
        sessionManager.resetStates()
        
        runnable = object : Runnable {
            override fun run() {
                try {
                    checkCurrentApp()
                    handler.postDelayed(this, 200)
                    ServiceHealthChecker.checkServiceHealth(this@AppMonitorService)
                } catch (e: Exception) {
                    Log.e(TAG, "❌ Erreur dans la boucle", e)
                    handler.postDelayed(this, 1000)
                }
            }
        }
        
        handler.post(runnable!!)
    }
    
    private fun checkCurrentApp() {
        val currentApp = appDetector.getCurrentForegroundApp()
        sessionManager.handleAppDetection(currentApp, notificationManager)
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "📲 Commande reçue: ${intent?.action}")
        
        when (intent?.action) {
            "RESTART" -> sessionManager.resetStates()
            "SIMULATE_INSTAGRAM" -> notificationManager.forceSendInstagramNotification()
            "SIMULATE_TIKTOK" -> notificationManager.forceSendTikTokNotification()
        }
        
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? = null
    
    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "💤 Service en cours d'arrêt")
        
        runnable?.let { handler.removeCallbacks(it) }
        if (wakeLock?.isHeld == true) wakeLock?.release()
        
        // Redémarrer automatiquement
        val intent = Intent(this, AppMonitorService::class.java)
        intent.action = "RESTART"
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }
}