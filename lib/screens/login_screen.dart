import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _auth = AuthService();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController(); // New Controller
  bool _isLoading = false;
  bool _isRegistering = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // Helper method to handle the login flow
  Future<void> _handleSignIn(Future<dynamic> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await signInMethod();
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _handleEmailAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Please fill in all fields");
      return;
    }

    if (_isRegistering && _nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = "Please enter your full name");
      return;
    }

    _handleSignIn(() async {
      if (_isRegistering) {
        await _auth.registerWithEmail(
          _emailController.text,
          _passwordController.text,
          _nameController.text.trim(),
        );
        // Save name to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('saved_user_name', _nameController.text.trim());
      } else {
        await _auth.signInWithEmail(
          _emailController.text,
          _passwordController.text,
        );
      }
    });
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
                Text(
                  _isRegistering
                      ? "Create a new account"
                      : "Authorized Staff Only",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 48),

                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  // 1. Google Sign In Button (PRIMARY)
                  _authButton(
                    label: "Continue with Google",
                    icon: Icons.g_mobiledata_rounded,
                    color: Colors.white,
                    textColor: Colors.black87,
                    onPressed: () => _handleSignIn(_auth.signInWithGoogle),
                  ),
                  const SizedBox(height: 24),

                  const Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "OR",
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 2. Email/Password Section (SECONDARY)
                  if (_isRegistering) ...[
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Full Name",
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                  ],

                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: "Email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),

                  _authButton(
                    label: _isRegistering ? "Register" : "Sign In",
                    icon: _isRegistering
                        ? Icons.person_add_rounded
                        : Icons.login_rounded,
                    color: Colors.blueGrey.shade800,
                    textColor: Colors.white,
                    onPressed: _handleEmailAuth,
                  ),

                  const SizedBox(height: 24),
                  // Toggle Login/Register
                  TextButton(
                    onPressed: () => setState(() {
                      _isRegistering = !_isRegistering;
                      _errorMessage = "";
                    }),
                    child: Text(
                      _isRegistering
                          ? "Already have an account? Sign In"
                          : "Don't have an account? Register",
                      style: const TextStyle(color: Colors.blueAccent),
                    ),
                  ),
                ],

                // Error Message Display                if (_errorMessage.isNotEmpty) ...[
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
