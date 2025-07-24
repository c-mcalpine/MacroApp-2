import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:logger/logger.dart';

import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final logger = Logger(
    level: kReleaseMode ? Level.off : Level.info,
  );

  try {
    final appConfig = AppConfig();
    await appConfig.initialize();
    logger.i('✅ AppConfig initialized');

    await Supabase.initialize(
      url: appConfig.supabaseUrl,
      anonKey: appConfig.supabaseAnonKey,
    );
    logger.i('✅ Supabase initialized');

    await SupabaseService.initialize();
    logger.i('✅ SupabaseService initialized');

    ApiService.init();
    logger.i('✅ ApiService initialized');

  } catch (e, s) {
    logger.e('❌ Error during app initialization', error: e, stackTrace: s);
  }

  runApp(MyApp(logger: logger));
}

class MyApp extends StatelessWidget {
  final Logger logger;
  
  const MyApp({Key? key, required this.logger}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return provider.ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        title: 'Macro App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.deepOrange,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          textTheme: ThemeData.dark().textTheme.copyWith(
            bodyLarge: const TextStyle(fontFamily: 'Lexend'),
            bodyMedium: const TextStyle(fontFamily: 'Lexend'),
            bodySmall: const TextStyle(fontFamily: 'Lexend'),
          ),
        ),
        navigatorKey: AuthService.navigatorKey,
        home: FutureBuilder<bool>(
          future: () async {
            try{
              return await AuthService.isAuthenticated();
            } catch (e, s) {
              logger.e('❌ Error checking authentication', error: e, stackTrace: s);
              return false;
            }
          }(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.deepOrange),
                  ),
                ),
              );
            }

                        final isAuthenticated = snapshot.data ?? false;
            if (isAuthenticated) {
              // Get auth data and update AuthProvider
              AuthService.getAuthData().then((authData) {
                if (authData != null) {
                  final context = AuthService.navigatorKey.currentContext;
                  if (context != null && context.mounted) {
                    provider.Provider.of<AuthProvider>(context, listen: false).login(
                      authData['user_id'],
                      userName: authData['user_name'],
                    );
                  }
                }
              }).catchError((e, s) {
                logger.e('❌ Error loading auth data', error: e, stackTrace: s);
              });
            }

            return provider.Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                return authProvider.isAuthenticated
                    ? HomeScreen(
                        onLogout: () async {
                          await AuthService.logout();
                          authProvider.logout();
                        },
                      )
                    : const LoginScreen();
              },
            );
          },
        ),
      ),
    );
  }
}