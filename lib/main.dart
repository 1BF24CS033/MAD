import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/user_provider.dart';
import 'providers/session_provider.dart';
import 'providers/project_provider.dart';
import 'providers/reward_provider.dart';
import 'providers/mentor_provider.dart';
import 'providers/help_request_provider.dart';
import 'theme/app_theme.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'screens/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env
  await dotenv.load(fileName: '.env');

  // Initialise Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

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
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => RewardProvider()),
        ChangeNotifierProvider(create: (_) => MentorProvider()),
        ChangeNotifierProvider(create: (_) => HelpRequestProvider()),
      ],
      child: MaterialApp(
        title: 'Benkyo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            // Show a loading spinner only during the initial startup auth check
            if (userProvider.initializing) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            if (userProvider.onboardingComplete) {
              return const _AppLoader();
            }
            return const WelcomeScreen();
          },
        ),
      ),
    );
  }
}

/// Loads all remote data once the user is authenticated, then shows HomeScreen.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll() async {
    await Future.wait([
      context.read<SessionProvider>().loadData(),
      context.read<ProjectProvider>().loadData(),
      context.read<RewardProvider>().loadData(),
      context.read<MentorProvider>().loadMentors(),
      context.read<HelpRequestProvider>().loadData(),
    ]);
    if (mounted) setState(() => _loaded = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeScreen();
  }
}
