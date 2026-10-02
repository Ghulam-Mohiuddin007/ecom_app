import 'package:ecom_app/auth/auth_screen.dart';
import 'package:ecom_app/checkout/delivery_tracking_screen.dart';
import 'package:ecom_app/feed/cart_screen.dart';
import 'package:ecom_app/feed/vibe_feed_screen.dart';
import 'package:ecom_app/onboarding/onboarding_screen.dart';
import 'package:ecom_app/onboarding/splash_scree.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // Replace these with your actual Supabase Project URL and Anon/Publishable Key
  await Supabase.initialize(
    url: 'https://bcllmbrzkujkxhqdakae.supabase.co',
    publishableKey: 'sb_publishable_4Xk6APjs3BIW89dQOXd3UQ_OhYh2L06',
  );

  runApp(const VibeVaultApp());
}

// Global helper accessor for your Supabase client across the app
final supabase = Supabase.instance.client;

class VibeVaultApp extends StatelessWidget {
  const VibeVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeVault',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF7F00FF),
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7F00FF),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      initialRoute: '/splash',
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/auth': (context) => const AuthScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/feed': (context) => const VibeFeedScreen(),
        '/cart': (context) => const CartScreen(),
        '/tracking': (context) => const DeliveryTrackingScreen(orderId: 'VV-ACTIVE'),
      },
    );
  }
}
