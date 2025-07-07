import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:instab/services/notification_service.dart';

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  
  Timer? _timer;
  Timer? _notificationTimer;
  int _timeSpent = 0;
  int _notificationInterval = 60; // Commence par 1 minute
  String _currentApp = "";
  bool _isTracking = false;
  bool _firstNotificationSent = false;
  final NotificationService _notificationService = NotificationService();
  
  int get timeSpent => _timeSpent;
  int get notificationInterval => _notificationInterval;
  String get currentApp => _currentApp;
  bool get isTracking => _isTracking;
  
  factory TimerService() {
    return _instance;
  }
  
  TimerService._internal() {
    debugPrint('🕒 TimerService initialized');
  }
  
  void startTracking(String appName) {
    // Seulement tracker Instagram et TikTok
    if (!appName.contains('Instagram') && !appName.contains('TikTok')) {
      debugPrint('🕒 Not tracking non-social media app: $appName');
      return;
    }
    
    // Si on est déjà en train de tracker cette app, ne rien faire
    if (_isTracking && _currentApp == appName) return;
    
    debugPrint('🕒 Starting to track app: $appName');
    
    // Si on était en train de tracker une autre app, réinitialiser
    if (_isTracking && _currentApp != appName) {
      reset();
    }
    
    _isTracking = true;
    _currentApp = appName;
    _firstNotificationSent = false; // Réinitialiser pour la première notification
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeSpent++;
      notifyListeners();
    });
    
    // Envoyer immédiatement la première notification de prévention
    _sendFirstNotification();
    
    // Puis démarrer le timer pour les notifications suivantes
    _startNotificationSchedule();
  }
  
  Future<void> _sendFirstNotification() async {
    if (_firstNotificationSent) return;
    
    _firstNotificationSent = true;
    final notificationService = NotificationService();
    
    String message = "Tu es sûr(e) de vouloir aller sur $_currentApp maintenant ?";
    
    debugPrint('🕒 Sending first warning notification');
    
    try {
      await notificationService.showNotification(
        title: 'ATTENTION - $_currentApp',
        body: message,
      );
    } catch (e) {
      debugPrint('🕒 Error sending first notification: $e');
    }
  }
  
  void pauseTracking() {
    if (!_isTracking) return;
    
    debugPrint('🕒 Pausing tracking for: $_currentApp');
    
    _timer?.cancel();
    _notificationTimer?.cancel();
    _isTracking = false;
    notifyListeners();
  }
  
  void stopTracking() {
    pauseTracking();
    reset();
  }
  
  void reset() {
    _timeSpent = 0;
    _notificationInterval = 60; // Remettre à 1 minute
    _currentApp = "";
    _isTracking = false;
    _firstNotificationSent = false;
    notifyListeners();
  }
  
  void _startNotificationSchedule() {
    _notificationTimer?.cancel();
    
    debugPrint('🕒 Starting notification schedule with first interval: $_notificationInterval seconds');
    
    _notificationTimer = Timer.periodic(Duration(seconds: _notificationInterval), (timer) {
      debugPrint('🕒 Notification timer triggered!');
      _sendNotification();
      _updateNotificationInterval();
    });
  }
  
  void _updateNotificationInterval() {
    int previousInterval = _notificationInterval;
    
    if (_notificationInterval > 30) {
      _notificationInterval = 30; // Après 1 minute -> toutes les 30 secondes
    } else if (_notificationInterval > 15) {
      _notificationInterval = 15; // Après 30 secondes -> toutes les 15 secondes
    } else if (_notificationInterval > 10) {
      _notificationInterval = 10; // Après 15 secondes -> toutes les 10 secondes
    } else if (_notificationInterval > 5) {
      _notificationInterval = 5; // Après 10 secondes -> toutes les 5 secondes
    } else if (_notificationInterval > 2) {
      _notificationInterval = 2; // Après 5 secondes -> toutes les 2 secondes
    } else if (_notificationInterval > 1) {
      _notificationInterval = 1; // Finalement toutes les secondes
    }
    
    if (previousInterval != _notificationInterval) {
      debugPrint('🕒 Notification interval updated from $previousInterval to $_notificationInterval seconds');
      
      // Redémarrer le timer avec le nouvel intervalle
      _notificationTimer?.cancel();
      _notificationTimer = Timer.periodic(Duration(seconds: _notificationInterval), (timer) {
        _sendNotification();
      });
    }
    
    notifyListeners();
  }
  
  Future<void> _sendNotification() async {
    if (!_isTracking) return;
    
    final notificationService = NotificationService();
    String message = _getNotificationMessage();
    
    debugPrint('🕒 Sending time-warning notification: $message');
    
    try {
      await notificationService.showNotification(
        title: 'TEMPS ÉCOULÉ - $_currentApp',
        body: message,
      );
    } catch (e) {
      debugPrint('🕒 Error sending notification: $e');
    }
  }
  
  String _getNotificationMessage() {
    int minutes = _timeSpent ~/ 60;
    int seconds = _timeSpent % 60;
    
    // Messages de plus en plus insistants selon le temps passé
    if (_timeSpent < 60) {
      return 'Tu as déjà passé ${seconds}s sur $_currentApp !';
    } else if (_timeSpent < 120) {
      return 'Ça fait déjà 1 minute que tu es sur $_currentApp ! Il est temps de faire une pause.';
    } else if (_timeSpent < 300) {
      return 'ATTENTION : ${minutes}min ${seconds}s sur $_currentApp ! C\'est beaucoup trop !';
    } else {
      return 'ARRÊTE TOUT DE SUITE $_currentApp !!! ${minutes}min ${seconds}s de perdues !';
    }
  }
  
  // Méthode pour tester manuellement l'envoi de notification
  Future<void> sendManualNotification() async {
    debugPrint('🕒 Sending manual notification test');
    final notificationService = NotificationService();
    
    try {
      // Envoyer une notification test claire et directe
      await notificationService.showNotification(
        title: 'TEST MANUEL',
        body: 'Notification de test envoyée manuellement!',
      );
    } catch (e) {
      debugPrint('🕒 Error sending manual notification: $e');
    }
  }
}
