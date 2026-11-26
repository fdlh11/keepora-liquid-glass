import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/navbar_screen.dart';
import 'screens/notifikasi_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/lupa_password_screen.dart';
import 'screens/verif_otp_screen.dart';
import 'screens/password_baru_screen.dart';

const String _themePrefKey = 'keepora_theme_mode';

// NavigatorKey global agar notifikasi bisa mengarahkan ke halaman Notifikasi dari mana saja
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// Pengontrol tema global aplikasi (Default mengikuti tema sistem HP)
final ValueNotifier<ThemeMode> appThemeNotifier =
    ValueNotifier<ThemeMode>(ThemeMode.system);

// Membaca tema tersimpan sebelum aplikasi dirender
Future<void> loadSavedTheme() async {
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString(_themePrefKey);
  if (savedTheme == 'dark') {
    appThemeNotifier.value = ThemeMode.dark;
  } else if (savedTheme == 'light') {
    appThemeNotifier.value = ThemeMode.light;
  } else {
    appThemeNotifier.value = ThemeMode.system;
  }
}

// Mengubah tema sekaligus menyimpannya ke memori lokal HP
Future<void> setAppTheme(bool isDark) async {
  appThemeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(_themePrefKey, isDark ? 'dark' : 'light');
}

void _navigateToNotifikasiFromTap() {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null || !user.emailVerified) return;

  final nav = appNavigatorKey.currentState;
  if (nav == null) return;

  // Pastikan tumpukan dasar berada di '/home' (NavbarScreen), lalu buka NotifikasiScreen
  nav.pushNamedAndRemoveUntil('/home', (route) => false);
  nav.push(
    MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await loadSavedTheme();
  await NotificationService.instance.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final TextTheme _baseTextTheme;

  @override
  void initState() {
    super.initState();
    _baseTextTheme = GoogleFonts.robotoTextTheme().copyWith(
      displayLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      displayMedium: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      displaySmall: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      headlineLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      headlineMedium: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      headlineSmall: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.montserrat(fontWeight: FontWeight.bold),
      titleMedium: GoogleFonts.montserrat(fontWeight: FontWeight.w600),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.setNotificationTapHandler((_) {
        _navigateToNotifikasiFromTap();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          themeMode: currentMode,
          themeAnimationDuration: Duration.zero,
          theme: ThemeData(
            brightness: Brightness.light,
            textTheme: _baseTextTheme,
            appBarTheme: AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            scaffoldBackgroundColor: Colors.white,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0056C6),
              brightness: Brightness.light,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            textTheme: _baseTextTheme.apply(
              bodyColor: Colors.white,
              displayColor: Colors.white,
            ),
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF121212),
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            scaffoldBackgroundColor: const Color(0xFF121212),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0056C6),
              brightness: Brightness.dark,
            ),
          ),
          debugShowCheckedModeBanner: false,
          title: 'Keepora',
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashScreen(),
            '/splash': (context) => const SplashScreen(),
            '/onboarding': (context) => const OnboardingScreen(),
            '/login': (context) => const LoginScreen(),
            '/register': (context) => const RegisterScreen(),
            '/LupaPassword': (context) => const LupaPasswordScreen(),
            '/verifOTP': (context) => const VerifOtpScreen(),
            '/passwordBaru': (context) => const PasswordBaruScreen(),
            '/home': (context) => const NavbarScreen(),
            '/notifikasi': (context) => const NotifikasiScreen(),
          },
        );
      },
    );
  }
}

// Widget Penjaga Sesi Login Otomatis
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.hasData && snapshot.data != null) {
          User user = snapshot.data!;
          if (user.emailVerified) {
            return const NavbarScreen();
          }
        }

        return const SplashScreen();
      },
    );
  }
}