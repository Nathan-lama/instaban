import 'dart:async';

class AppDetectionService {
  static final AppDetectionService _instance = AppDetectionService._internal();
  
  final List<String> socialApps = [
    'com.instagram.android',
    'com.zhiliaoapp.musically', // TikTok
  ];
  
  String currentApp = "Aucune app détectée";
  bool isMonitoring = false;
  StreamController<String> appDetectedController = StreamController<String>.broadcast();
  Timer? _checkTimer;
  int _simulationCounter = 0;
  
  factory AppDetectionService() {
    return _instance;
  }
  
  AppDetectionService._internal();
  
  Stream<String> get onAppDetected => appDetectedController.stream;
  
  void startMonitoring() {
    if (isMonitoring) return;
    
    isMonitoring = true;
    _checkTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkCurrentApp();
    });
    
    appDetectedController.add("Surveillance en cours...");
  }
  
  void stopMonitoring() {
    isMonitoring = false;
    _checkTimer?.cancel();
    currentApp = "Surveillance arrêtée";
    appDetectedController.add(currentApp);
  }
  
  void _checkCurrentApp() {
    // Pour la démonstration, nous alternerons entre les applications
    // Dans une vraie application, il faudrait utiliser une API pour détecter l'app en cours
    _simulationCounter++;
    
    // Simulation: alterner entre Instagram et autre chose pour démontrer la détection
    if (_simulationCounter % 15 < 7) { // 7 secondes sur Instagram
      if (currentApp != "Instagram") {
        currentApp = "Instagram";
        appDetectedController.add(currentApp);
      }
    } else if (_simulationCounter % 15 < 10) { // 3 secondes sur TikTok
      if (currentApp != "TikTok") {
        currentApp = "TikTok";
        appDetectedController.add(currentApp);
      }
    } else { // 5 secondes sur autre chose
      if (currentApp != "Autre application") {
        currentApp = "Autre application";
        appDetectedController.add(currentApp);
      }
    }
  }
  
  bool isSocialMediaApp(String appPackage) {
    return socialApps.contains(appPackage) || 
           appPackage.contains("Instagram") ||
           appPackage.contains("TikTok");
  }
  
  void dispose() {
    _checkTimer?.cancel();
    appDetectedController.close();
  }
}
