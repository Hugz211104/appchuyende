import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginScreen;
  const RegisterScreen({super.key, required this.showLoginScreen});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface, // Sync background color
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: widget.showLoginScreen, // Go back to login screen
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chào mừng bạn đến với cộng đồng!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 48),

                // Email Field
                _buildTextField(_emailController, 'Email', Icons.email_outlined),
                const SizedBox(height: 16),

                // Password Field
                _buildTextField(_passwordController, 'Mật khẩu', Icons.lock_outline, obscureText: true),
                const SizedBox(height: 16),

                // Confirm Password Field
                _buildTextField(_confirmPasswordController, 'Xác nhận mật khẩu', Icons.lock_outline, obscureText: true),
                const SizedBox(height: 32),

                // Sign Up Button
                _isLoading 
                    ? const Center(child: CircularProgressIndicator()) 
                    : _buildSignUpButton(),

                const SizedBox(height: 24),

                // Login Button
                _buildLoginButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, IconData icon, {bool obscureText = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ]
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return ElevatedButton(
      onPressed: _signUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 5,
        shadowColor: AppColors.primary.withOpacity(0.4),
      ),
      child: Text(
        'Đăng ký',
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Đã có tài khoản?', style: TextStyle(color: AppColors.textSecondary)),
        TextButton(
          onPressed: widget.showLoginScreen,
          child: const Text(
            'Đăng nhập ngay',
            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
