import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:frontend/screens/auth/auth_gatekeeper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
// 🚀 NEW: IMPORT LOCAL NOTIFICATIONS FOR NATIVE SIREN ALARMS
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// 🚀 CREATE THE NOTIFICATION PLUGIN INSTANCE
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

// 🚀 FEATURE 1: BACKGROUND NOTIFICATION HANDLER
// This must be a top-level function (outside of any class)
@pragma('vm:entry-point') // 👈 EXTREMELY IMPORTANT FOR BACKGROUND EXECUTION
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background message: ${message.messageId}");
}

void main() async {
  // Ensure Flutter bindings are initialized before calling Firebase
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase for the current platform (Web/Android/iOS)
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 🚀 FEATURE 1: REGISTER THE BACKGROUND HANDLER
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🚀 FEATURE 2: NATIVE ANDROID SIREN CHANNEL
    // This creates the high-priority channel that looks for the MP3 in res/raw/siren.mp3
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'sos_alerts', // ID MUST match the Python backend
      'High Risk SOS Alerts',
      description: 'This channel is used for urgent SOS sirens.',
      importance: Importance.max, // Forces banner to drop down over everything
      playSound: true,
      sound: RawResourceAndroidNotificationSound('siren'),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // FEATURE 11: ENABLE OFFLINE CACHING
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

  } catch (e) {
    debugPrint("Firebase initialization warning: $e");
  }

  // Run the main app
  runApp(const NyayaBridgeApp());
}

class NyayaBridgeApp extends StatelessWidget {
  const NyayaBridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NyayaBridge Platform',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D3142)),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const AuthGatekeeper(),
    );
  }
}