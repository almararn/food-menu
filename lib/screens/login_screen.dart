import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  bool _isLoading = false;
  String _errorMessage = '';

  // Helper method to handle the login flow
  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await signInMethod();
      // If successful, the StreamBuilder in main.dart will
      // automatically detect the change and show the HomeScreen.
    } catch (e) {
      setState(() {
        // Clean up the error message for the user
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon or Logo
                const Icon(
                  Icons.restaurant_menu_rounded,
                  size: 80,
                  color: Colors.blueGrey,
                ),
                const SizedBox(height: 24),
                const Text(
                  "TDK Food Portal",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  "Authorized Staff Only",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  // Google Sign In Button
                  _authButton(
                    label: "Sign in with Google",
                    icon: Icons.g_mobiledata_rounded,
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: () => _handleSignIn(_auth.signInWithGoogle),
                  ),
                  const SizedBox(height: 16),

                  // Apple Sign In Button
                  _authButton(
                    label: "Sign in with Apple",
                    icon: Icons.apple_rounded,
                    color: Colors.black,
                    textColor: Colors.white,
                    onPressed: () => _handleSignIn(_auth.signInWithApple),
                  ),
                ],

                // Error Message Display
                if (_errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _authButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: textColor),
        label: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: color == Colors.white
                ? const BorderSide(color: Colors.grey)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
