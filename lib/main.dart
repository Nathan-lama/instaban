import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

import 'package:instab/services/notification_service.dart';
import 'package:instab/services/app_detection_service.dart';
import 'package:instab/services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser le service de notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TimerService()),
      ],
      child: const SocialMediaDetectorApp(),
    ),
  );
}

class SocialMediaDetectorApp extends StatelessWidget {
  const SocialMediaDetectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Social Media Detector',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MonitoringPage(),
    );
  }
}

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final AppDetectionService _appDetectionService = AppDetectionService();
  late StreamSubscription<String> _appDetectionSubscription;
  String _currentApp = "Surveillance en cours...";
  
  @override
  void initState() {
    super.initState();
    // Démarre automatiquement le monitoring au lancement de l'app
    _setupAppDetectionListener();
    _startMonitoringAutomatically();
  }
  
  void _setupAppDetectionListener() {
    _appDetectionSubscription = _appDetectionService.onAppDetected.listen((appName) {
      setState(() {
        _currentApp = appName;
      });
      
      // Si une app de réseaux sociaux est détectée
      if (_appDetectionService.isSocialMediaApp(appName) ||
          appName.contains("Instagram") || appName.contains("TikTok")) {
        Provider.of<TimerService>(context, listen: false).startTracking(appName);
      } else {
        // Si l'utilisateur n'est plus sur une app de réseaux sociaux, arrêter le compteur
        Provider.of<TimerService>(context, listen: false).pauseTracking();
      }
    });
  }
  
  void _startMonitoringAutomatically() {
    _appDetectionService.startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Social Media Detector'),
        actions: [
          // Bouton pour tester les notifications
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Envoyer une notification de test
              NotificationService().sendTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notification de test envoyée!'))
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.visibility,
              size: 80,
              color: Colors.red,
            ),
            const SizedBox(height: 20),
            const Text(
              'Surveillance active en arrière-plan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Application détectée:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              _currentApp,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: _currentApp.contains('Instagram') || _currentApp.contains('TikTok') 
                    ? Colors.red 
                    : Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Consumer<TimerService>(
              builder: (context, timerService, child) {
                if (timerService.isTracking) {
                  return Column(
                    children: [
                      Text(
                        'Temps passé sur ${timerService.currentApp}:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${timerService.timeSpent}s',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Prochaine notification dans: ${timerService.notificationInterval}s',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  );
                } else {
                  return const Text(
                    'Aucune application surveillée actuellement',
                    style: TextStyle(fontSize: 16),
                  );
                }
              },
            ),
            const SizedBox(height: 20),
            // Bouton de test amélioré
            ElevatedButton.icon(
              icon: const Icon(Icons.notification_add, size: 24),
              label: const Text(
                'TESTER LES NOTIFICATIONS',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                debugPrint('Test notification button pressed');
                // Afficher un indicateur visuel
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Envoi de la notification de test...'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 1),
                  ),
                );
                // Envoyer la notification après un court délai
                Future.delayed(const Duration(milliseconds: 500), () {
                  NotificationService().sendTestNotification();
                });
              },
            ),
            const SizedBox(height: 10),
            // Bouton pour demander les permissions NPD
            TextButton.icon(
              icon: const Icon(Icons.settings, size: 20),
              label: const Text(
                'ACTIVER CONTOURNEMENT NPD',
                style: TextStyle(fontSize: 14),
              ),
              onPressed: () async {
                // Ouvrir les paramètres de l'application en utilisant permission_handler
                await openAppSettings();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Activez "Ne pas déranger - Accès" dans les permissions',
                      style: TextStyle(fontSize: 14),
                    ),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 5),
                  ),
                );
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'La surveillance des réseaux sociaux est active en arrière-plan.\nVous recevrez des notifications lorsque vous passerez trop de temps sur Instagram ou TikTok.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _appDetectionSubscription.cancel();
    _appDetectionService.dispose();
    super.dispose();
  }
}
