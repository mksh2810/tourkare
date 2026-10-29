import 'package:flutter/material.dart';
import 'package:tourkare/screens/auth/login.dart';
import 'package:tourkare/services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String code;

  const ResetPasswordScreen({super.key, required this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isValid = false;
  String? _email;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _verifyCode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final result = await AuthService.instance.verifyPasswordResetCode(
      code: widget.code,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isValid = result.success;
      _email = result.success ? result.message : null;
      _errorMessage = result.success ? null : result.message;
    });
  }

  Future<void> _savePassword() async {
    final password = _passwordController.text;
    if (password.length < 6) {
      setState(
        () => _errorMessage = 'Password should be at least 6 characters.',
      );
      return;
    }
    if (password != _confirmController.text) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    final result = await AuthService.instance.confirmPasswordReset(
      code: widget.code,
      newPassword: password,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (result.success) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Password updated'),
          content: const Text('You can now sign in with your new password.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } else {
      setState(() => _errorMessage = result.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : !_isValid
                    ? _buildInvalidState()
                    : _buildForm(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.link_off, size: 60, color: Colors.deepPurple),
        const SizedBox(height: 18),
        const Text(
          'Reset link unavailable',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          _errorMessage ?? 'This link is invalid or expired.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_reset, size: 54, color: Colors.deepPurple),
        const SizedBox(height: 18),
        const Text(
          'Create a new password',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        if (_email != null) ...[
          const SizedBox(height: 8),
          Text(_email!, style: TextStyle(color: Colors.grey.shade600)),
        ],
        const SizedBox(height: 24),
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          decoration: InputDecoration(
            labelText: 'New password',
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _confirmController,
          obscureText: _obscureConfirm,
          decoration: InputDecoration(
            labelText: 'Confirm password',
            suffixIcon: IconButton(
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icon(
                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
              ),
            ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _savePassword,
            child: _isSaving
                ? const CircularProgressIndicator()
                : const Text('Update password'),
          ),
        ),
      ],
    );
  }
}
