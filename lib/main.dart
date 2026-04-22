import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'providers/user_provider.dart';
import 'providers/session_provider.dart';
import 'providers/project_provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const BenkyoApp());
}

class BenkyoApp extends StatelessWidget {
  const BenkyoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()..loadUser()),
        ChangeNotifierProvider(create: (_) => SessionProvider()..loadDummyData()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()..loadDummyData()),
      ],
      child: MaterialApp(
        title: 'Benkyo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            if (userProvider.onboardingComplete) {
              return const HomeScreen();
            }
            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}
