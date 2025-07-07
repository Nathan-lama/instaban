import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NativeService {
  static const platform = MethodChannel('com.example.instab/service');
  
  static Future<void> startMonitoringService() async {
    try {
      await platform.invokeMethod('startService');
      debugPrint('🔧 Service Android natif démarré');
    } on PlatformException catch (e) {
      debugPrint('🔧 Erreur démarrage service: ${e.message}');
    }
  }
  
  static Future<void> stopMonitoringService() async {
    try {
      await platform.invokeMethod('stopService');
      debugPrint('🔧 Service Android natif arrêté');
    } on PlatformException catch (e) {
      debugPrint('🔧 Erreur arrêt service: ${e.message}');
    }
  }
  
  static Future<void> simulateInstagram() async {
    try {
      await platform.invokeMethod('simulateInstagram');
      debugPrint('🔧 Simulation Instagram lancée');
    } on PlatformException catch (e) {
      debugPrint('🔧 Erreur simulation: ${e.message}');
    }
  }
  
  static Future<void> simulateTikTok() async {
    try {
      await platform.invokeMethod('simulateTikTok');
      debugPrint('🔧 Simulation TikTok lancée');
    } on PlatformException catch (e) {
      debugPrint('🔧 Erreur simulation: ${e.message}');
    }
  }
}
