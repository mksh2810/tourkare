import 'package:flutter/material.dart';
import 'package:tourkare/services/auth_service.dart';
import 'package:tourkare/screens/auth/login.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignupScreen extends StatefulWidget {
  // CHANGED: fixed invalid constructor
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool obscurePass = true;
  bool confirmObscurePass = true;

  // CHANGE 1: Added loading state
  bool isLoading = false;

  @override
  void dispose() {
    // CHANGE 2: Dispose controllers properly
    nameController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmPassController.dispose();

    super.dispose();
  }

  // CHANGE 3: Signup logic moved into separate function
  Future<void> _signup() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passController.text;
    final confirmPassword = confirmPassController.text;

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please fill all fields')));
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.instance.signup(
        name: name,
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Signup failed. Please try again.'),
          ),
        );
      }

      // On success, Firebase is already signed in.
      // AuthGate will automatically display Homepage.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signup error: $e')));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _googleSignup() async {
    setState(() {
      isLoading = true;
    });

    try {
      final result = await AuthService.instance.signupWithGoogle();

      if (!mounted) return;

      if (!result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message ?? 'Google signup failed.')),
        );
      }

      // AuthGate will handle navigation after success.
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Google signup error: $e')));
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
              const SizedBox(height: 20),

              const Text(
                'Create Account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              Text(
                'Create an account and start planning your next adventure',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 35),

              _field(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_2_outlined,
              ),

              const SizedBox(height: 16),

              _field(
                controller: emailController,
                label: 'Email Address',
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 16),

              _field(
                controller: passController,
                label: 'Password',
                icon: Icons.key_outlined,
                obscureText: obscurePass,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      obscurePass = !obscurePass;
                    });
                  },
                  icon: Icon(
                    obscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _field(
                controller: confirmPassController,
                label: 'Confirm Password',
                icon: Icons.key_outlined,
                obscureText: confirmObscurePass,
                suffix: IconButton(
                  onPressed: () {
                    setState(() {
                      confirmObscurePass = !confirmObscurePass;
                    });
                  },
                  // CHANGE 8: Fixed this icon.
                  // Previously it incorrectly checked obscurePass.
                  icon: Icon(
                    confirmObscurePass
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,

                child: ElevatedButton(
                  // CHANGE 9: Disable button while signing up
                  onPressed: isLoading ? null : _signup,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  // CHANGE 10: Show loading indicator
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
                          'Create Account',
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
                  onPressed: isLoading ? null : _googleSignup,

                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        '/google_logo.svg',
                        height: 22,
                        width: 22,
                      ),

                      const SizedBox(width: 12),

                      const Text(
                        'Sign up with Google',
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
                    'Already have an account?',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),

                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            // CHANGE 11:
                            // No need for setState here.
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                    child: const Text(
                      'Login',
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

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffix,

        filled: true,
        fillColor: Colors.white,

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
