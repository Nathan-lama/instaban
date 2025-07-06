import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:instab/services/notification_service.dart';

class TimerService extends ChangeNotifier {
  static final TimerService _instance = TimerService._internal();
  
  Timer? _timer;
  Timer? _notificationTimer;
  int _timeSpent = 0;
  int _notificationInterval = 10; // Commencer à 10 secondes pour tester plus rapidement
  String _currentApp = "";
  bool _isTracking = false;
  final NotificationService _notificationService = NotificationService();
  
  int get timeSpent => _timeSpent;
  int get notificationInterval => _notificationInterval;
  String get currentApp => _currentApp;
  bool get isTracking => _isTracking;
  
  factory TimerService() {
    return _instance;
  }
  
  TimerService._internal() {
    // Envoyer une notification test au démarrage du service
    Future.delayed(const Duration(seconds: 3), () {
      _notificationService.sendTestNotification();
    });
  }
  
  void startTracking(String appName) {
    // Si on est déjà en train de tracker cette app, ne rien faire
    if (_isTracking && _currentApp == appName) return;
    
    debugPrint('Starting to track app: $appName');
    
    // Si on était en train de tracker une autre app, réinitialiser
    if (_isTracking && _currentApp != appName) {
      reset();
    }
    
    _isTracking = true;
    _currentApp = appName;
    
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeSpent++;
      notifyListeners();
      debugPrint('Time spent on $_currentApp: $_timeSpent seconds');
    });
    
    _startNotificationSchedule();
    notifyListeners();
  }
  
  void pauseTracking() {
    if (!_isTracking) return;
    
    debugPrint('Pausing tracking for: $_currentApp');
    
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
    _notificationInterval = 10; // Commencer à 10 secondes pour tester plus rapidement
    _currentApp = "";
    _isTracking = false;
    notifyListeners();
  }
  
  void _startNotificationSchedule() {
    _notificationTimer?.cancel();
    
    debugPrint('Starting notification schedule with interval: $_notificationInterval seconds');
    
    _notificationTimer = Timer.periodic(Duration(seconds: _notificationInterval), (timer) {
      debugPrint('Notification timer triggered!');
      _sendNotification();
      _updateNotificationInterval();
    });
  }
  
  void _updateNotificationInterval() {
    int previousInterval = _notificationInterval;
    
    if (_notificationInterval > 30) {
      _notificationInterval = 30;
    } else if (_notificationInterval > 20) {
      _notificationInterval = 20;
    } else if (_notificationInterval > 10) {
      _notificationInterval = 10;
    } else if (_notificationInterval > 5) {
      _notificationInterval = 5;
    } else if (_notificationInterval > 1) {
      _notificationInterval = 1;
    }
    
    if (previousInterval != _notificationInterval) {
      debugPrint('Notification interval updated from $previousInterval to $_notificationInterval seconds');
      
      // Redémarrer le timer avec le nouvel intervalle
      _startNotificationSchedule();
    }
    
    notifyListeners();
  }
  
  Future<void> _sendNotification() async {
    final notificationService = NotificationService();
    String message = _getNotificationMessage();
    
    debugPrint('Sending invasive notification: $message');
    
    await notificationService.showNotification(
      title: '⚠️ ALERTE TEMPS D\'ÉCRAN! ⚠️',
      body: message,
    );
  }
  
  String _getNotificationMessage() {
    int minutes = _timeSpent ~/ 60;
    int seconds = _timeSpent % 60;
    
    if (minutes > 0) {
      return 'FERME $_currentApp MAINTENANT! Tu y as déjà passé ${minutes}min ${seconds}s!! 🚨';
    } else {
      return 'ARRÊTE $_currentApp TOUT DE SUITE! Déjà ${seconds}s de perdues! 🚨';
    }
  }
  
  // Méthode pour tester manuellement l'envoi de notification
  Future<void> sendManualNotification() async {
    debugPrint('📱 Sending manual notification test');
    final notificationService = NotificationService();
    
    // Envoyer une notification test claire et directe
    await notificationService.showNotification(
      title: 'TEST MANUEL',
      body: 'Notification de test envoyée manuellement!',
    );
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _notificationTimer?.cancel();
    super.dispose();
  }
}
