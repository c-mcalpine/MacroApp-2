import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'config/app_config.dart';
import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: ".env");
  
  // Initialize app configuration
  final appConfig = AppConfig();
  await appConfig.initialize();
  
  // Initialize Supabase with configuration values
  await Supabase.initialize(
    url: appConfig.supabaseUrl,
    anonKey: appConfig.supabaseAnonKey,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
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
        home: Consumer<AuthProvider>(
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
        ),
      ),
    );
  }
}