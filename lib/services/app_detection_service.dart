import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:usage_stats/usage_stats.dart';

class AppDetectionService {
  static final AppDetectionService _instance = AppDetectionService._internal();
  
  final Map<String, String> socialApps = {
    'com.instagram.android': 'Instagram',
    'com.zhiliaoapp.musically': 'TikTok', 
    'com.ss.android.ugc.trill': 'TikTok',
  };
  
  String currentApp = "Aucune app détectée";
  bool isMonitoring = false;
  StreamController<String> appDetectedController = StreamController<String>.broadcast();
  Timer? _checkTimer;
  bool _hasUsageStatsPermission = false;
  int _lastTimestamp = 0;
  bool _isSocialAppActive = false;
  
  factory AppDetectionService() {
    return _instance;
  }
  
  AppDetectionService._internal();
  
  Stream<String> get onAppDetected => appDetectedController.stream;
  
  Future<void> initialize() async {
    // Demander les permissions nécessaires pour détecter l'usage
    await _requestUsagePermission();
  }
  
  Future<void> _requestUsagePermission() async {
    // Vérifier si nous avons déjà la permission
    _hasUsageStatsPermission = await UsageStats.checkUsagePermission() ?? false;
    
    if (!_hasUsageStatsPermission) {
      debugPrint('👀 Requesting usage stats permission');
      
      // Rediriger vers les paramètres de permission
      await UsageStats.grantUsagePermission();
      
      // Vérifier à nouveau après la tentative d'obtention de permission
      _hasUsageStatsPermission = await UsageStats.checkUsagePermission() ?? false;
    }
    
    debugPrint('👀 Usage stats permission: ${_hasUsageStatsPermission ? "GRANTED" : "DENIED"}');
  }
  
  Future<void> startMonitoring() async {
    if (isMonitoring) return;
    
    await initialize();
    
    if (!_hasUsageStatsPermission) {
      debugPrint('👀 Cannot start monitoring: usage stats permission denied');
      appDetectedController.add("Permission refusée. Veuillez autoriser l'accès aux statistiques d'utilisation");
      return;
    }
    
    debugPrint('👀 Starting real app monitoring service');
    isMonitoring = true;
    _isSocialAppActive = false;
    currentApp = "Aucune app détectée";
    appDetectedController.add(currentApp);
    
    // Vérifier l'application en cours toutes les 2 secondes
    _checkTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _checkCurrentApp();
    });
  }
  
  void stopMonitoring() {
    isMonitoring = false;
    _checkTimer?.cancel();
    currentApp = "Surveillance arrêtée";
    appDetectedController.add(currentApp);
  }
  
  Future<void> _checkCurrentApp() async {
    if (!_hasUsageStatsPermission || !isMonitoring) return;
    
    try {
      // Obtenir les statistiques d'utilisation pour les 5 dernières secondes
      DateTime endDate = DateTime.now();
      // Obtenir les données d'utilisation pour les 3 dernières secondes seulement
      DateTime startDate = endDate.subtract(const Duration(seconds: 3)); 
      
      // Obtenir les statistiques d'usage
      List<UsageInfo> usageList = await UsageStats.queryUsageStats(startDate, endDate);
      
      // Vérifier si les applications de réseaux sociaux sont actuellement utilisées
      bool foundSocialApp = false;
      String detectedApp = "";
      int newTimestamp = 0;
      
      if (usageList.isNotEmpty) {
        for (var usage in usageList) {
          if (usage.packageName != null && 
              usage.lastTimeUsed != null && 
              socialApps.containsKey(usage.packageName)) {
            
            int timestamp = int.tryParse(usage.lastTimeUsed ?? "0") ?? 0;
            
            // Si c'est un timestamp plus récent que celui qu'on a vu précédemment
            if (timestamp > _lastTimestamp) {
              detectedApp = socialApps[usage.packageName] ?? usage.packageName!;
              newTimestamp = timestamp;
              foundSocialApp = true;
              debugPrint('👀 Found recent activity: $detectedApp (${usage.packageName}) at $timestamp');
            }
          }
        }
      }
      
      // Si on a trouvé une application sociale récente
      if (foundSocialApp) {
        _lastTimestamp = newTimestamp;
        if (!_isSocialAppActive || currentApp != detectedApp) {
          _isSocialAppActive = true;
          currentApp = detectedApp;
          debugPrint('👀 DETECTED: User is actively using $currentApp');
          appDetectedController.add(currentApp);
        }
      } 
      // Si on n'a pas trouvé d'activité récente d'applications sociales
      else if (_isSocialAppActive) {
        _isSocialAppActive = false;
        currentApp = "Aucune app de réseau social";
        debugPrint('👀 User has stopped using social media apps');
        appDetectedController.add(currentApp);
      }
    } catch (e) {
      debugPrint('👀 Error checking current app: $e');
    }
  }
  
  bool isSocialMediaApp(String appName) {
    return socialApps.values.contains(appName) || 
           appName.contains("Instagram") ||
           appName.contains("TikTok");
  }
  
  void dispose() {
    _checkTimer?.cancel();
    appDetectedController.close();
  }
}