import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _permissionsGranted = false;
  bool _dndPermissionGranted = false;
  int _notificationId = 0;
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal();
  
  Future<void> initialize() async {
    debugPrint('🔔 Initializing NotificationService');
    
    // Demander toutes les permissions nécessaires y compris NPD
    await _requestAllPermissions();
    
    // Configuration pour Android et iOS
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      requestCriticalPermission: true, // Demander la permission pour les alertes critiques sur iOS
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('🔔 Notification clicked: ${response.payload}');
      },
    );
    
    // Configurer les canaux de notification
    await _setupNotificationChannels();
    
    // Envoyer une notification de test après initialisation
    Future.delayed(const Duration(seconds: 2), () => sendTestNotification());
  }
  
  Future<void> _requestAllPermissions() async {
    debugPrint('🔔 Requesting all required permissions');
    
    // Demander la permission pour les notifications standard
    final notificationStatus = await Permission.notification.request();
    _permissionsGranted = notificationStatus.isGranted;
    debugPrint('🔔 Notification permission: ${notificationStatus.isGranted ? "GRANTED" : "DENIED"}');
    
    // Demander la permission pour accéder à la politique de notification (nécessaire pour NPD)
    if (Platform.isAndroid) {
      final dndStatus = await Permission.accessNotificationPolicy.request();
      _dndPermissionGranted = dndStatus.isGranted;
      debugPrint('🔔 DND policy access permission: ${dndStatus.isGranted ? "GRANTED" : "DENIED"}');
      
      // Afficher un message si la permission NPD n'est pas accordée
      if (!_dndPermissionGranted) {
        debugPrint('⚠️ DND bypass will not work without ACCESS_NOTIFICATION_POLICY permission');
      }
    }
  }
  
  Future<void> _setupNotificationChannels() async {
    debugPrint('🔔 Setting up notification channels with DND bypass capabilities');
    
    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidPlugin = 
          _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
          
      if (androidPlugin != null) {
        // Supprimer les anciens canaux
        await androidPlugin.deleteNotificationChannel('social_detector_urgent');
        await androidPlugin.deleteNotificationChannel('social_detector_alarm');
        await androidPlugin.deleteNotificationChannel('social_detector_emergency');
        
        // Créer un canal d'alarme de haute importance sans référence à un son personnalisé
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'social_detector_alarm', 
            'Alarmes critiques',
            description: 'Notifications d\'urgence qui doivent contourner le mode NPD',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: const Color(0xFFFF0000),
            // Supprimé la référence au son personnalisé
          ),
        );
        
        // Créer un second canal pour les notifications d'urgence
        await androidPlugin.createNotificationChannel(
          AndroidNotificationChannel(
            'social_detector_emergency', 
            'Alertes d\'urgence',
            description: 'Notifications critiques nécessitant une attention immédiate',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            ledColor: const Color(0xFFFF0000),
          ),
        );
        
        debugPrint('🔔 Android notification channels created successfully');
      }
    }
  }
  
  Future<void> showNotification({
    required String title,
    required String body,
    int? id,
  }) async {
    debugPrint('🔔 Attempting to show notification that bypasses DND: $title - $body');
    
    if (!_permissionsGranted) {
      debugPrint('🔔 Cannot show notification: permissions not granted');
      await _requestAllPermissions();
      if (!_permissionsGranted) return;
    }
    
    try {
      final notificationId = id ?? _getNextNotificationId();
      
      if (Platform.isAndroid) {
        // Utiliser un canal d'alarme pour contourner NPD
        final androidAlarmDetails = AndroidNotificationDetails(
          'social_detector_alarm',
          'Alarmes critiques',
          channelDescription: 'Notifications d\'urgence qui doivent contourner le mode NPD',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
          enableLights: true,
          ledColor: const Color(0xFFFF0000),
          ledOnMs: 1000,
          ledOffMs: 500,
          fullScreenIntent: true,
          visibility: NotificationVisibility.public,
          category: AndroidNotificationCategory.alarm,
          ticker: 'ALERTE URGENTE',
          ongoing: true, // Notification persistante
          autoCancel: false,
          channelShowBadge: true,
          icon: 'mipmap/ic_launcher',
          audioAttributesUsage: AudioAttributesUsage.alarm,
          // Supprimé la référence au son personnalisé
        );
        
        final notificationDetails = NotificationDetails(
          android: androidAlarmDetails,
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            interruptionLevel: InterruptionLevel.critical, // Niveau critique pour iOS
            // Supprimé la référence au son personnalisé
          ),
        );
        
        // Envoyer la notification d'urgence
        debugPrint('🔔 Sending EMERGENCY notification to bypass DND');
        await _notifications.show(
          notificationId,
          '🚨 ALERTE URGENTE 🚨',
          '⚠️ $body',
          notificationDetails,
        );
        
        // Envoyer une deuxième notification avec un autre canal (approche alternative)
        final androidEmergencyDetails = AndroidNotificationDetails(
          'social_detector_emergency',
          'Alertes d\'urgence',
          channelDescription: 'Notifications critiques nécessitant une attention immédiate',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.call, // Utiliser la catégorie "appel"
          ongoing: true,
          icon: 'mipmap/ic_launcher',
        );
        
        final emergencyNotificationDetails = NotificationDetails(
          android: androidEmergencyDetails,
        );
        
        // Envoi d'une seconde notification 1 seconde après
        Future.delayed(const Duration(seconds: 1), () async {
          await _notifications.show(
            notificationId + 100,
            '⚠️ ACTION REQUISE ⚠️',
            'ARRÊTEZ IMMÉDIATEMENT $body!',
            emergencyNotificationDetails,
          );
        });
      } else if (Platform.isIOS) {
        // Configuration iOS pour les notifications critiques
        const iosCriticalDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          // Supprimé la référence au son personnalisé
          interruptionLevel: InterruptionLevel.critical,
        );
        
        final notificationDetails = const NotificationDetails(iOS: iosCriticalDetails);
        
        await _notifications.show(
          notificationId,
          '🚨 ALERTE CRITIQUE 🚨',
          '⚠️ $body',
          notificationDetails,
        );
      }
      
      debugPrint('🔔 Notifications sent successfully');
    } catch (e) {
      debugPrint('🔔 Error showing notification: $e');
    }
  }

  int _getNextNotificationId() {
    return _notificationId++;
  }

  Future<void> sendTestNotification() async {
    debugPrint('🔔 Sending test notification that should bypass DND');
    await showNotification(
      title: 'TEST BYPASS DND',
      body: 'Cette notification devrait contourner le mode NPD! 🔴',
    );
  }
}