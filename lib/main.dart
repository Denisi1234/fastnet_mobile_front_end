import 'package:fastnet_mobile_front_end/ui/screens/main_screen.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/onboarding_screen.dart';
import 'package:fastnet_mobile_front_end/models/app_settings.dart';
import 'package:fastnet_mobile_front_end/providers/bookings_provider.dart';
import 'package:fastnet_mobile_front_end/providers/wishlist_provider.dart';
import 'package:fastnet_mobile_front_end/providers/user_session_provider.dart';
import 'package:fastnet_mobile_front_end/ui/screens/auth/user_session.dart';
import 'package:fastnet_mobile_front_end/services/api_service.dart';
import 'package:fastnet_mobile_front_end/services/notification_service.dart';
import 'package:fastnet_mobile_front_end/models/destination.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:fastnet_mobile_front_end/config/constants.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await UserSession.init();
  await ApiService.init();
  MapboxOptions.setAccessToken(AppConstants.mapboxApiKey);
  loadDestinationsFromApi(); // Load in background to prevent slow startup
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BookingsProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
        ChangeNotifierProvider(create: (_) => UserSessionProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: AppSettings.instance,
      builder: (context, child) {
        final hasSeenOnboarding = context.watch<UserSessionProvider>().hasSeenOnboarding;
        return MaterialApp(
          scaffoldMessengerKey: NotificationService.messengerKey,
          debugShowCheckedModeBanner: false,
          title: 'FASTNET',
          theme: ThemeData(fontFamily: 'AirbnbCereal'),
          home: hasSeenOnboarding ? const MainScreen() : const OnboardingScreen(),
        );
      },
    );
  }
}

