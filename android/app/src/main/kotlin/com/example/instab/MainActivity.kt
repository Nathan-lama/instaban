package com.example.instab

import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.instab/service"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "🚀 Application démarrée")
        
        // Démarrer le service automatiquement au lancement
        startMonitoringService()
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startService" -> {
                    startMonitoringService()
                    result.success("Service démarré")
                }
                "stopService" -> {
                    stopMonitoringService()
                    result.success("Service arrêté")
                }
                "simulateInstagram" -> {
                    simulateInstagram()
                    result.success("Simulation Instagram lancée")
                }
                "simulateTikTok" -> {
                    simulateTikTok()
                    result.success("Simulation TikTok lancée")
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
    
    private fun startMonitoringService() {
        Log.d("MainActivity", "🚀 Démarrage du service de surveillance")
        val serviceIntent = Intent(this, AppMonitorService::class.java)
        
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                startForegroundService(serviceIntent)
            } else {
                startService(serviceIntent)
            }
            Log.d("MainActivity", "✅ Service démarré avec succès")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Erreur lors du démarrage du service", e)
        }
    }
    
    private fun stopMonitoringService() {
        val serviceIntent = Intent(this, AppMonitorService::class.java)
        stopService(serviceIntent)
    }
    
    private fun simulateInstagram() {
        val intent = Intent(this, AppMonitorService::class.java)
        intent.action = "SIMULATE_INSTAGRAM"
        startService(intent)
    }
    
    private fun simulateTikTok() {
        val intent = Intent(this, AppMonitorService::class.java)
        intent.action = "SIMULATE_TIKTOK"
        startService(intent)
    }
}
