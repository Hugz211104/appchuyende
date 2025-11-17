import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/utils/app_colors.dart';
import 'package:chuyende/utils/dimens.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterScreen;
  const LoginScreen({super.key, required this.showRegisterScreen});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = Provider.of<AuthService>(context, listen: false);

    final userCredential = await authService.signInWithEmailAndPassword(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (userCredential == null) {
      CustomDialog.show(
        context,
        title: "Lỗi Đăng Nhập",
        description: "Đăng nhập thất bại. Vui lòng kiểm tra lại thông tin.",
        dialogType: DialogType.ERROR,
      );
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppDimens.space24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'GenNews',
                    textAlign: TextAlign.center,
                    style: textTheme.displayLarge?.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(height: AppDimens.space12),
                  Text(
                    'Khám phá. Chia sẻ. Kết nối.',
                    textAlign: TextAlign.center,
                    style: textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: AppDimens.space64),

                  // Use labelText for floating label effect
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty || !value.contains('@')) {
                        return 'Vui lòng nhập một email hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.space16),

                  // Use labelText for floating label effect
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppDimens.space32),

                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _signIn,
                          child: const Text('Đăng nhập'),
                        ),
                  const SizedBox(height: AppDimens.space24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Chưa có tài khoản?', style: textTheme.bodyMedium),
                      TextButton(
                        onPressed: widget.showRegisterScreen,
                        child: const Text('Đăng ký ngay'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
