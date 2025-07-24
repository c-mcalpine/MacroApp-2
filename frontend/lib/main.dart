import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:google_fonts/google_fonts.dart';
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

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
          textTheme: GoogleFonts.lexendTextTheme(ThemeData.dark().textTheme),
        ),
        navigatorKey: AuthService.navigatorKey,
        home: FutureBuilder<bool>(
          future: AuthService.isAuthenticated(),
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
                  if (context != null) {
                    provider.Provider.of<AuthProvider>(context, listen: false).login(
                      authData['user_id'],
                      userName: authData['user_name'],
                    );
                  }
                }
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
                    : LoginScreen();
              },
            );
          },
        ),
      ),
    );
  }
}