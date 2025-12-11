import 'package:chuyende/providers/theme_provider.dart';
import 'package:chuyende/screens/change_password_screen.dart';
import 'package:chuyende/services/auth_service.dart';
import 'package:chuyende/widgets/custom_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      await authService.signOut();
      // Pop all routes until back to the very first screen.
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.show(context, title: 'Đăng xuất thất bại', description: 'Đã xảy ra lỗi: $e', dialogType: DialogType.ERROR);
      }
    }
  }

  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn muốn đăng xuất không?'),
        actions: <Widget>[
          TextButton(child: const Text('Hủy'), onPressed: () => Navigator.of(dialogContext).pop()),
          TextButton(child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)), onPressed: () {
            Navigator.of(dialogContext).pop(); // Close the dialog
            _logout();
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        children: [
          _buildSectionHeader(context, 'Giao diện'),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              label: 'Chế độ tối',
              value: isDarkMode,
              onChanged: (value) {
                themeProvider.toggleTheme(value);
              },
            ),
          ]),
          _buildSectionHeader(context, 'Tài khoản'),
          _buildSettingsCard([
             _buildNavigationTile(
              context: context,
              label: 'Đổi mật khẩu',
              icon: CupertinoIcons.lock_fill,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => const ChangePasswordScreen()));
              },
            ),
            _buildDivider(),
            _buildLogoutTile(context),
          ]),
           _buildSectionHeader(context, 'Thông báo'),
          _buildSettingsCard([
            _buildSwitchTile(
              context: context,
              label: 'Thông báo đẩy',
              value: true, // Replace with actual notification state
              onChanged: (value) {
                // TODO: Implement notification preference logic
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({required BuildContext context, required String label, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNavigationTile({required BuildContext context, required String label, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.logout, color: Colors.red),
      title: Text('Đăng xuất', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.red)),
      onTap: _showLogoutConfirmationDialog,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.only(left: 56.0), // Align with title text
      child: Divider(height: 1),
    );
  }
}
