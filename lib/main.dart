/// @author [Chong Jun Xiang]
/// @email [chongjx-wm22@student.tarc.edu.my]
/// @create date 2025-09-11 15:51:22
/// @modify date 2025-09-11 15:51:22
/// @desc [MainPage: Entry point of the application, handles theming and authentication state.]
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:job_management_workshop/controllers/main_controller.dart';
import 'package:job_management_workshop/helpers/app_logger.dart';
import 'package:job_management_workshop/helpers/connection_helper.dart';
import 'package:job_management_workshop/providers/connection_status_provider.dart';
import 'package:job_management_workshop/providers/session_provider.dart';
import 'package:job_management_workshop/services/background_sync_service.dart';
import 'package:job_management_workshop/services/sqlite_service.dart';
import 'package:job_management_workshop/services/supabase_service.dart';
import 'package:job_management_workshop/views/apps/bottom_navigation.dart';
import 'package:job_management_workshop/widgets/utils/connection_status_bar_widget.dart';
import 'package:provider/provider.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleTheme(bool value) {
    _isDarkMode = value;
    notifyListeners();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize core services first
    AppLogger.info('Initializing Supabase...');
    await SupabaseService.initialize();

    AppLogger.info('Initializing SQLite...');
    await SQLiteService().initialize();

    // Initialize session provider and attempt to restore session
    AppLogger.info('Initializing Session Provider...');
    final sessionProvider = SessionProvider();
    await sessionProvider.initialize();

    // Initialize background sync service
    AppLogger.info('Initializing Background Sync Service...');
    await BackgroundSyncService.initialize();

    AppLogger.info('All services initialized successfully');

    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => sessionProvider),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => ConnectionStatusProvider()),
        ],
        child: const MainApp(),
      ),
    );
  } catch (e) {
    AppLogger.error('Error during app initialization: $e');
    // You might want to show an error screen or retry initialization
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Failed to initialize app'),
                const SizedBox(height: 8),
                Text('Error: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Restart the app
                    main();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Job Management Workshop',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Render the connection status bar in the app builder so it overlays
      // every route / page in the app (global overlay).
      builder: (context, child) {
        final connectionQuality = Provider.of<ConnectionStatusProvider>(
          context,
        ).quality;
        // Use ThemeProvider directly to pick a safe background color immediately
        final themeProvider = Provider.of<ThemeProvider>(context);
        final backgroundColor = themeProvider.isDarkMode
            ? const Color(0xFF121212)
            : Colors.white;

        // Ensure background is painted with theme's scaffoldBackgroundColor while
        // still overlaying the connection status bar on top.
        return Stack(
          children: [
            // Animated background container to avoid visual flicker during theme changes.
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              color: backgroundColor,
              child: child ?? const SizedBox.shrink(),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ConnectionStatusBarWidget(quality: connectionQuality),
            ),
          ],
        );
      },
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        if (session.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (session.isLoggedIn) {
          final themeProvider = Provider.of<ThemeProvider>(context);
          return BottomNavigation(
            isDarkMode: themeProvider.isDarkMode,
            onThemeToggle: (value) => themeProvider.toggleTheme(value),
          );
        } else {
          return const LoginPage();
        }
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _error;

  final TextEditingController _staffIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleStaffLogin() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final staffId = _staffIdController.text.trim();
    final password = _passwordController.text;
    final mainController = MainController();
    final loginResult = await mainController.loginStaff(staffId, password);
    if (!loginResult.success) {
      if (!mounted) return;
      setState(() {
        _error = loginResult.error ?? 'Login failed. Please try again.';
        _isLoading = false;
      });
      return;
    }
    try {
      final sessionProvider = Provider.of<SessionProvider>(
        context,
        listen: false,
      );

      // When Supabase is unavailable, try offline sign-in using local SQLite
      if (!sessionProvider.isSupabaseAvailable()) {
        final offlineOk = await sessionProvider.signInOffline(
          staffId,
          password,
        );
        if (!offlineOk) {
          if (!mounted) return;
          setState(() {
            _error = 'Offline login failed. Please check credentials.';
            _isLoading = false;
          });
          return;
        }
      } else {
        // Online sign in - will store session and sync local DB inside provider
        final success = await sessionProvider.signInWithStaffCredentials(
          staffId,
          password,
          context: context,
        );
        if (!success) {
          if (!mounted) return;
          setState(() {
            _error = 'Login failed. Please check your credentials.';
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Login failed. Please try again.';
        _isLoading = false;
      });
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    // Connection status is now managed globally by ConnectionStatusProvider
  }

  @override
  Widget build(BuildContext context) {
    final connectionQuality = Provider.of<ConnectionStatusProvider>(
      context,
    ).quality;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset(
                'assets/images/logo.jpg',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),
              Text(
                'Staff Login',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sign in with your Staff ID and password',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              // Connection status indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    connectionQuality == ConnectionQuality.online
                        ? Icons.cloud_done
                        : connectionQuality == ConnectionQuality.weak
                        ? Icons.cloud_queue
                        : Icons.cloud_off,
                    color: connectionQuality == ConnectionQuality.online
                        ? Colors.green
                        : connectionQuality == ConnectionQuality.weak
                        ? Colors.orange
                        : Colors.red,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    connectionQuality == ConnectionQuality.online
                        ? 'Online'
                        : connectionQuality == ConnectionQuality.weak
                        ? 'Weak connection — sign in may fail'
                        : 'Offline — first-time login requires internet',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: connectionQuality == ConnectionQuality.online
                          ? Colors.green
                          : connectionQuality == ConnectionQuality.weak
                          ? Colors.orange
                          : Colors.red,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Staff ID input
              TextField(
                controller: _staffIdController,
                decoration: const InputDecoration(
                  labelText: 'Staff ID',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                  hintText: 'e.g., 2501',
                ),
                keyboardType: TextInputType.number,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              // Password input
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                obscureText: _obscurePassword,
              ),
              const SizedBox(height: 24),
              // Sign in button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleStaffLogin,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        )
                      : const Text('Sign In'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(25), // was withOpacity(0.1)
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withAlpha(77),
                    ), // was withOpacity(0.3)
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[700],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  /// Disposes the controllers.
  @override
  void dispose() {
    _staffIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
