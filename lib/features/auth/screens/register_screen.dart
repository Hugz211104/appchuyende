import 'dart:math';
import 'dart:ui';
import 'package:chuyende/features/auth/services/auth_service.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const RegisterScreen({super.key, required this.showLoginScreen});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _animationController.forward();
  }

  Future<void> _signUp() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      CustomDialog.show(context, title: "Lỗi", description: "Mật khẩu không khớp.", dialogType: DialogType.ERROR);
      return;
    }
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      CustomDialog.show(context, title: "Lỗi", description: "Vui lòng điền đầy đủ thông tin.", dialogType: DialogType.ERROR);
      return;
    }
    setState(() => _isLoading = true);
    final userCredential = await _authService.registerWithEmailAndPassword(_emailController.text.trim(), _passwordController.text.trim());
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (userCredential == null) {
      CustomDialog.show(context, title: "Lỗi Đăng Ký", description: "Đăng ký thất bại. Email có thể đã được sử dụng.", dialogType: DialogType.ERROR);
    } else {
      CustomDialog.show(
        context,
        title: "Thành Công",
        description: "Đăng ký thành công! Vui lòng đăng nhập.",
        dialogType: DialogType.SUCCESS,
        onOk: widget.showLoginScreen,
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedWidget(Widget child, {required double start, required double end}) {
    final curve = CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(curve),
      child: FadeTransition(
        opacity: curve,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     _buildAnimatedWidget(
                       Column(
                         children:[
                            Text('Tạo tài khoản', style: GoogleFonts.poppins(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Text('Gia nhập cộng đồng Tin Tức!', style: GoogleFonts.inter(color: Colors.white.withOpacity(0.9), fontSize: 16)),
                         ]
                       ),
                       start: 0.0, end: 0.4
                     ),
                    const SizedBox(height: 60),
                    _buildAnimatedWidget(
                      _buildTextField(_emailController, 'Email', false),
                      start: 0.2, end: 0.6
                    ),
                    const SizedBox(height: 16),
                    _buildAnimatedWidget(
                      _buildTextField(_passwordController, 'Mật khẩu', true),
                       start: 0.3, end: 0.7
                    ),
                    const SizedBox(height: 16),
                     _buildAnimatedWidget(
                       _buildTextField(_confirmPasswordController, 'Xác nhận mật khẩu', true),
                       start: 0.4, end: 0.8
                     ),
                    const SizedBox(height: 30),
                     _buildAnimatedWidget(
                       _isLoading ? const CircularProgressIndicator(color: Colors.white) : _buildSignUpButton(),
                       start: 0.5, end: 0.9
                     ),
                    const SizedBox(height: 20),
                     _buildAnimatedWidget(
                       _buildLoginButton(),
                       start: 0.6, end: 1.0
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
  Widget _buildSignUpButton() => GestureDetector(onTap: _signUp, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 18), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), gradient: const LinearGradient(colors: [Color(0xFF0A84FF), Color(0xFFE84A9B)]), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), spreadRadius: 1, blurRadius: 8)]), child: Center(child: Text('Đăng ký', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)))));
  Widget _buildLoginButton() => GestureDetector(onTap: widget.showLoginScreen, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF81C7F5), width: 2)), child: Center(child: Text('Đã có tài khoản? Đăng nhập', style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)))));
  Widget _buildAbstractShape({required Color color, required double size}) => Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class ParticlesLayer extends StatefulWidget { // Re-using the same particle widget
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
            child: Opacity(opacity: p.opacity, child: Container(width: p.size, height: p.size, decoration: BoxDecoration(shape: p.isCircle ? BoxShape.circle : BoxShape.rectangle, color: Colors.white))),
          )).toList(),
    );
  }
}

class Particle { // Re-using the same particle model
  final double x, y, size, opacity;
  final bool isCircle;
  Particle() : x = Random().nextDouble(), y = Random().nextDouble(), size = Random().nextDouble() * 5 + 2, opacity = Random().nextDouble() * 0.5 + 0.1, isCircle = Random().nextBool();
}
