import 'dart:math';
import 'dart:ui';
import 'package:chuyende/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password.');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = ''; });
    final userCredential = await _authService.signInWithEmailAndPassword(_emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (userCredential == null) {
      setState(() => _errorMessage = 'Failed to sign in. Please check your credentials.');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Layers
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF81C7F5), Color(0xFFF7A7A6)],
              ),
            ),
          ),
          Positioned(top: -100, left: -100, child: _buildAbstractShape(color: Colors.white.withOpacity(0.08), size: 300)),
          Positioned(bottom: -150, right: -50, child: _buildAbstractShape(color: Colors.white.withOpacity(0.1), size: 400)),
          const ParticlesLayer(),

          // Main UI
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('GenNews', style: GoogleFonts.poppins(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Text('Discover. Share. Connect.', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                    const SizedBox(height: 60),
                    _buildTextField(_emailController, 'Username or Email', false),
                    const SizedBox(height: 16),
                    _buildTextField(_passwordController, 'Password', true),
                    const SizedBox(height: 30),
                    if (_errorMessage.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 10.0), child: Text(_errorMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    _isLoading ? const CircularProgressIndicator(color: Colors.white) : _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildSignUpButton(),
                    const SizedBox(height: 40),
                    Text('Or continue with social media', style: TextStyle(color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSocialIcon(Icons.facebook, color: const Color(0xFF1877F2)), // Facebook Blue
                        const SizedBox(width: 25),
                        _buildSocialIcon(Icons.close, color: Colors.black), // Placeholder for X
                        const SizedBox(width: 25),
                        _buildSocialIcon(Icons.play_arrow, color: const Color(0xFFDB4437)), // Google Red
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, bool obscureText) => TextField(controller: controller, obscureText: obscureText, decoration: InputDecoration(hintText: hintText, hintStyle: TextStyle(color: Colors.grey[500]), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20)));
  Widget _buildLoginButton() => GestureDetector(onTap: _signIn, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFFE84A9B)]), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 1, blurRadius: 8)]), child: Center(child: Text('Log In', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))));
  Widget _buildSignUpButton() => GestureDetector(onTap: widget.showRegisterScreen, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF81C7F5), width: 2)), child: Center(child: Text('Sign Up', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))));
  Widget _buildSocialIcon(IconData icon, {required Color color}) => Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: Icon(icon, color: color, size: 24));
  Widget _buildAbstractShape({required Color color, required double size}) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class ParticlesLayer extends StatefulWidget {
  const ParticlesLayer({super.key});
  @override
  State<ParticlesLayer> createState() => _ParticlesLayerState();
}

class _ParticlesLayerState extends State<ParticlesLayer> {
  late List<Particle> particles;
  @override
  void initState() {
    super.initState();
    particles = List.generate(40, (index) => Particle());
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: particles.map((p) => Positioned(
            top: p.y * size.height,
            left: p.x * size.width,
            child: Opacity(
              opacity: p.opacity,
              child: Container(
                width: p.size,
                height: p.size,
                decoration: BoxDecoration(shape: p.isCircle ? BoxShape.circle : BoxShape.rectangle, color: Colors.white),
              ),
            ),
          )).toList(),
    );
  }
}

class Particle {
  final double x, y, size, opacity;
  final bool isCircle;
  Particle()
      : x = Random().nextDouble(),
        y = Random().nextDouble(),
        size = Random().nextDouble() * 5 + 2,
        opacity = Random().nextDouble() * 0.5 + 0.1,
        isCircle = Random().nextBool();
}
