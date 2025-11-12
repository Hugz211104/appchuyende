import 'package:flutter/material.dart';

enum DialogType { SUCCESS, ERROR, INFO, WARNING }

class CustomDialog {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required DialogType dialogType,
    String okText = 'OK',
    Function()? onOk,
  }) {
    IconData icon;
    Color color;

    switch (dialogType) {
      case DialogType.SUCCESS:
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case DialogType.ERROR:
        icon = Icons.error_outline;
        color = Colors.red;
        break;
      case DialogType.INFO:
        icon = Icons.info_outline;
        color = Colors.blue;
        break;
      case DialogType.WARNING:
        icon = Icons.warning_amber_outlined;
        color = Colors.orange;
        break;
    }

    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) => Container(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Icon(icon, color: color, size: 28),
                  const SizedBox(width: 10),
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(description),
              actions: [
                TextButton(
                  onPressed: onOk ?? () => Navigator.of(context).pop(),
                  child: Text(okText, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
