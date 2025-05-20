import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart' as provider;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  print('Environment variables loaded:');
  print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  print('All env vars: ${dotenv.env}');
  
  // Initialize app configuration
  final appConfig = AppConfig();
  await appConfig.initialize();
  
  // Initialize Supabase with configuration values
  await Supabase.initialize(
    url: appConfig.supabaseUrl,
    anonKey: appConfig.supabaseAnonKey,
  );
  
  // Initialize SupabaseService
  await SupabaseService.initialize();
  
  ApiService.init(); // Initialize ApiService
  
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
              return Scaffold(
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