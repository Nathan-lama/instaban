package com.example.instab

import android.util.Log

class SessionManager {
    private val TAG = "SessionManager"
    
    // Variables pour le suivi
    private var isOnInstagram = false
    private var isOnTikTok = false
    private var instagramStartTime = 0L
    private var tiktokStartTime = 0L
    private var instagramLastNotif = 0L
    private var tiktokLastNotif = 0L
    private var lastDetectedApp: String? = null
    private var noAppDetectionCount = 0
    private var serviceStartTime = System.currentTimeMillis()
    private var lastSuccessfulDetection = 0L
    private var checkCounter = 0
    
    fun resetStates() {
        isOnInstagram = false
        isOnTikTok = false
        lastDetectedApp = null
        noAppDetectionCount = 0
        checkCounter = 0
    }
    
    fun handleAppDetection(currentApp: String?, notificationManager: NotificationManagerHelper) {
        val currentTime = System.currentTimeMillis()
        
        if (currentApp != null) {
            lastSuccessfulDetection = currentTime
            noAppDetectionCount = 0
            
            when {
                currentApp == "com.instagram.android" -> {
                    handleInstagramDetected(currentTime, false, notificationManager)
                }
                currentApp == "com.zhiliaoapp.musically" || currentApp == "com.ss.android.ugc.trill" -> {
                    handleTikTokDetected(currentTime, false, notificationManager)
                }
                else -> {
                    handleNoSocialApp(notificationManager)
                }
            }
            
            lastDetectedApp = currentApp
        } else {
            noAppDetectionCount++
            if (noAppDetectionCount >= 10) { // 2 secondes (10 * 200ms)
                handleNoSocialApp(notificationManager)
            }
        }
    }
    
    private fun handleInstagramDetected(currentTime: Long, forceNotification: Boolean, notificationManager: NotificationManagerHelper) {
        if (!isOnInstagram || forceNotification) {
            Log.d(TAG, "📱 NOUVELLE SESSION INSTAGRAM")
            isOnInstagram = true
            isOnTikTok = false
            instagramStartTime = currentTime
            instagramLastNotif = currentTime
            
            notificationManager.sendImmediateWarning("Instagram")
            notificationManager.updateServiceNotification()
        } else {
            // Vérifier le temps écoulé
            val timeSpent = (currentTime - instagramStartTime) / 1000
            val timeSinceLastNotif = (currentTime - instagramLastNotif) / 1000
            val interval = TimeCalculator.calculateInterval(timeSpent)
            
            if (timeSinceLastNotif >= interval) {
                notificationManager.sendTimeWarning("Instagram", timeSpent)
                instagramLastNotif = currentTime
            }
        }
    }
    
    private fun handleTikTokDetected(currentTime: Long, forceNotification: Boolean, notificationManager: NotificationManagerHelper) {
        if (!isOnTikTok || forceNotification) {
            Log.d(TAG, "📱 NOUVELLE SESSION TIKTOK")
            isOnTikTok = true
            isOnInstagram = false
            tiktokStartTime = currentTime
            tiktokLastNotif = currentTime
            
            notificationManager.sendImmediateWarning("TikTok")
            notificationManager.updateServiceNotification()
        } else {
            // Vérifier le temps écoulé
            val timeSpent = (currentTime - tiktokStartTime) / 1000
            val timeSinceLastNotif = (currentTime - tiktokLastNotif) / 1000
            val interval = TimeCalculator.calculateInterval(timeSpent)
            
            if (timeSinceLastNotif >= interval) {
                notificationManager.sendTimeWarning("TikTok", timeSpent)
                tiktokLastNotif = currentTime
            }
        }
    }
    
    private fun handleNoSocialApp(notificationManager: NotificationManagerHelper) {
        var stateChanged = false
        
        if (isOnInstagram) {
            Log.d(TAG, "👋 Fin session Instagram")
            isOnInstagram = false
            stateChanged = true
        }
        
        if (isOnTikTok) {
            Log.d(TAG, "👋 Fin session TikTok")
            isOnTikTok = false
            stateChanged = true
        }
        
        if (stateChanged) {
            notificationManager.updateServiceNotification()
        }
    }
    
    // Getters pour l'état
    fun isOnInstagram(): Boolean = isOnInstagram
    fun isOnTikTok(): Boolean = isOnTikTok
    fun getServiceStartTime(): Long = serviceStartTime
    fun getLastSuccessfulDetection(): Long = lastSuccessfulDetection
}