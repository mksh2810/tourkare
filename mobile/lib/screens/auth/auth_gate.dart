import 'package:flutter/material.dart';
import 'package:tourkare/services/auth_service.dart';
import 'package:tourkare/screens/auth/login.dart';
import 'package:tourkare/screens/homepage.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checkingSession = true;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
    await AuthService.instance.checkSession();
  } catch (e) {
    debugPrint('Session initialization failed: $e');
  } finally {
    if (mounted) {
      setState(() {
        _checkingSession = false;
      });
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    if (_checkingSession) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Colors.deepPurple),
        ),
      );
    }

    return AnimatedBuilder(
      animation: AuthService.instance,

      builder: (context, child) {
        if (AuthService.instance.isLoggedIn) {
          return const Homepage();
        }

        return const LoginScreen();
      },
    );
  }
}
