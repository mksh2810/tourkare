import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tourkare/services/auth_service.dart';
import 'package:tourkare/screens/auth/signup.dart';

class LoginScreen extends StatefulWidget {
  // CHANGE 1: Fixed invalid constructor
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  bool obscurePass = true;
  bool isLoading = false;

  // CHANGE 2: Dispose controllers
  @override
  void dispose() {
    _emailController.dispose();
    _passController.dispose();

    super.dispose();
  }

  // CHANGE 3: Added separate login function
  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password')),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.instance.login(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (result.success) {
        // AuthGate will navigate to Homepage automatically.
        // Do not push Homepage from here.
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Login failed. Please try again.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Login error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),

      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              const SizedBox(height: 30),

              const Text(
                'Welcome Back',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Login to continue planning your trips',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,

                decoration: InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: const Icon(Icons.email_outlined),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 18),

              TextField(
                controller: _passController,
                obscureText: obscurePass,

                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.key_outlined),

                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePass = !obscurePass;
                      });
                    },
                    icon: Icon(
                      obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,

                child: TextButton(
                  // CHANGE 7: Disable while loading
                  onPressed: isLoading
                      ? null
                      : () {
                          // Forgot password
                        },
                  child: const Text('Forgot Password'),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  // CHANGE 8: Use _login and disable while loading
                  onPressed: isLoading ? null : _login,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  // CHANGE 9: Show loading indicator
                  child: isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 52,

                child: OutlinedButton(
                  // CHANGE 10: Google button uses same loading state
                  onPressed: isLoading ? null : _googleLogin,

                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,

                    side: BorderSide(color: Colors.grey.shade300),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  // CHANGE 11: Show spinner during Google login
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.deepPurple,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'google_logo.svg',
                              height: 22,
                              width: 22,
                            ),

                            const SizedBox(width: 12),

                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  TextButton(
                    // CHANGE 12: Disable while loading
                    onPressed: isLoading
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignupScreen(),
                              ),
                            );
                          },

                    child: const Text(
                      'Sign Up', // CHANGE 13: Fixed "Sugn Up"
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Google Login
  Future<void> _googleLogin() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.instance.loginWithGoogle();

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Google login failed.')),
        );
      }

      // AuthGate handles successful navigation.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google login error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }
}
