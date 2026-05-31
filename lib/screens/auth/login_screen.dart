import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'register_screen.dart';
import '../client/client_home_screen.dart';
import '../provider/provider_home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = ''; });
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      final role = doc.data()?['role'] ?? 'client';
      if (!mounted) return;
      if (role == 'provider') {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ProviderHomeScreen()));
      } else {
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ClientHomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message ?? 'Login failed'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text('ServiceConnect',
                  style: TextStyle(fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB))),
              const SizedBox(height: 8),
              const Text('Sign in to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 48),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Email'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('Password'),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(_errorMessage,
                    style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Login',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen())),
                  child: const Text("Don't have an account? Register"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}