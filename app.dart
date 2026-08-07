import 'package:flutter/material.dart';
import 'services/auth_service.dart';
import 'screens/login/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'utils/theme.dart';
import 'utils/constants.dart';

class DpsErpApp extends StatelessWidget {
  const DpsErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const _StartupGate(),
    );
  }
}

/// Restores a previous session on launch, then routes to the
/// dashboard or the login screen accordingly.
class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _checking = true;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await AuthService.instance.seedDefaultAdminIfNeeded();
    final user = await AuthService.instance.restoreSession();
    if (mounted) {
      setState(() {
        _authenticated = user != null;
        _checking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return _authenticated ? const DashboardScreen() : const LoginScreen();
  }
}
