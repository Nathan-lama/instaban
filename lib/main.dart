import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';
import 'package:usage_stats/usage_stats.dart';

import 'package:instab/services/notification_service.dart';
import 'package:instab/services/timer_service.dart';
import 'package:instab/services/native_service.dart';

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
  late StreamSubscription<String> _appDetectionSubscription;
  String _currentApp = "Surveillance en cours...";
  bool _permissionGranted = false;
  
  @override
  void initState() {
    super.initState();
    _checkPermissions();
    _setupAppDetectionListener();
  }
  
  Future<void> _checkPermissions() async {
    // Vérifier les permissions de notifications et d'usage des applications
    var notifPermission = await Permission.notification.status;
    bool usagePermission = await UsageStats.checkUsagePermission() ?? false;
    
    setState(() {
      _permissionGranted = notifPermission.isGranted && usagePermission;
    });
    
    debugPrint('📱 Notification permission: ${notifPermission.isGranted}');
    debugPrint('📱 Usage stats permission: $usagePermission');
    
    if (_permissionGranted) {
      // Démarrer SEULEMENT le service Android natif
      await NativeService.startMonitoringService();
      debugPrint('📱 Service Android natif démarré - Service Flutter désactivé');
    } else {
      _showPermissionDialog();
    }
  }
  
  void _showPermissionDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('🔐 Permissions requises'),
            content: const Text(
              'Cette application a besoin de 2 permissions critiques:\n\n'
              '1️⃣ NOTIFICATIONS: Pour vous alerter\n'
              '2️⃣ ACCÈS AUX DONNÉES D\'UTILISATION: Pour détecter Instagram/TikTok\n\n'
              '⚠️ Sans ces permissions, l\'application ne peut pas fonctionner.\n\n'
              'Après avoir cliqué "Ouvrir les paramètres":\n'
              '• Allez dans "Autorisations spéciales"\n'
              '• Activez "Accès aux données d\'utilisation"\n'
              '• Puis revenez à l\'application'
            ),
            actions: [
              TextButton(
                child: const Text('Ouvrir les paramètres'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  
                  // D'abord essayer d'ouvrir directement les permissions d'usage
                  try {
                    await UsageStats.grantUsagePermission();
                  } catch (e) {
                    // Si ça ne marche pas, ouvrir les paramètres généraux
                    await openAppSettings();
                  }
                  
                  // Montrer un message d'aide
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Allez dans "Autorisations spéciales" → "Accès aux données d\'utilisation" → Activez pour cette app',
                        style: TextStyle(fontSize: 14),
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 8),
                    ),
                  );
                },
              ),
              TextButton(
                child: const Text('Vérifier à nouveau'),
                onPressed: () {
                  Navigator.of(context).pop();
                  _checkPermissions();
                },
              ),
            ],
          );
        }
      );
    });
  }

  void _setupAppDetectionListener() {
    // Désactiver complètement l'écoute du service Flutter
    // car le service Android natif gère tout maintenant
    _appDetectionSubscription = Stream<String>.empty().listen((_) {});
    
    // Simuler un état par défaut
    setState(() {
      _currentApp = "Service Android natif actif";
    });
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
            Text(
              _permissionGranted 
                ? 'Surveillance active en arrière-plan' 
                : 'En attente des permissions...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _permissionGranted ? Colors.red : Colors.orange,
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
            // Bouton d'aide pour les permissions
            if (!_permissionGranted) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.settings_applications),
                label: const Text('ACTIVER LES PERMISSIONS'),
                onPressed: () async {
                  try {
                    await UsageStats.grantUsagePermission();
                  } catch (e) {
                    await openAppSettings();
                  }
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Cherchez "Accès aux données d\'utilisation" dans les permissions spéciales',
                        style: TextStyle(fontSize: 14),
                      ),
                      backgroundColor: Colors.blue,
                      duration: Duration(seconds: 6),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('VÉRIFIER LES PERMISSIONS'),
                onPressed: () {
                  _checkPermissions();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 32),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ Permissions accordées! Service natif actif.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('REDÉMARRER'),
                          onPressed: () async {
                            await NativeService.startMonitoringService();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Service Android redémarré'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.camera_alt),
                          label: const Text('TESTER INSTAGRAM'),
                          onPressed: () async {
                            await NativeService.simulateInstagram();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Test Instagram lancé'),
                                backgroundColor: Colors.pink,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.video_library),
                      label: const Text('TESTER TIKTOK'),
                      onPressed: () async {
                        await NativeService.simulateTikTok();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Test TikTok lancé'),
                            backgroundColor: Colors.black,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
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
    super.dispose();
  }
}