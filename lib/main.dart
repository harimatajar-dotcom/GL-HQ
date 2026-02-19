import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/tasks_provider.dart';
import 'providers/projects_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/team_provider.dart';
import 'providers/report_provider.dart';
import 'providers/hr_report_provider.dart';
import 'providers/asset_provider.dart';
import 'providers/analytics_provider.dart';
import 'providers/touchpoint_provider.dart';
import 'providers/chatlogs_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GetleadHQApp());
}

class GetleadHQApp extends StatelessWidget {
  const GetleadHQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => TasksProvider()),
        ChangeNotifierProvider(create: (_) => ProjectsProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => TeamProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => HRReportProvider()),
        ChangeNotifierProvider(create: (_) => AssetProvider()),
        ChangeNotifierProvider(create: (_) => AnalyticsProvider()),
        ChangeNotifierProvider(create: (_) => TouchpointProvider()),
        ChangeNotifierProvider(create: (_) => ChatlogsProvider()),
      ],
      child: MaterialApp(
        title: 'Getlead HQ',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: Consumer<AuthProvider>(
          builder: (_, auth, __) {
            if (auth.loading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            return auth.loggedIn ? const HomeScreen() : const LoginScreen();
          },
        ),
      ),
    );
  }
}
