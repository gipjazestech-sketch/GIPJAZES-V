import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _submit() async {
    setState(() => _isLoading = true);
    try {
      String uEmail = _emailController.text.trim();
      String uPass = _passwordController.text.trim();
      String uName = _usernameController.text.trim();

      if (isLogin) {
        await ApiService().login(uEmail, uPass);
      } else {
        await ApiService().register(uName, uEmail, uPass);
      }
      Navigator.of(context).pushReplacementNamed('/feed');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD4AF37), // Solid Real Gold
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "GIPJAZES",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.black, // Dark text
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isLogin ? "Log in to your account" : "Sign up for GIPJAZES",
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87, // Dark charcoal
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 50),
                if (!isLogin) ...[
                  _buildTextField(
                      _usernameController, "Username", Icons.person_outline),
                  const SizedBox(height: 16),
                ],
                _buildTextField(
                    _emailController, "Email", Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField(
                    _passwordController, "Password", Icons.lock_outline,
                    isPassword: true),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black, // Solid Black button
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            isLogin ? "Log in" : "Sign up",
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () => setState(() => isLogin = !isLogin),
                  child: RichText(
                    text: TextSpan(
                      text: isLogin
                          ? "Don't have an account? "
                          : "Already have an account? ",
                      style: const TextStyle(color: Colors.black87),
                      children: [
                        TextSpan(
                          text: isLogin ? "Sign up" : "Log in",
                          style: const TextStyle(
                              color: Colors.black, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFDECB2)
            .withOpacity(0.4), // Subtle light gold/transparent glass
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black12), // Dark outline
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: const TextStyle(color: Colors.black), // Dark text input
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.black54, size: 20),
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black38),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
