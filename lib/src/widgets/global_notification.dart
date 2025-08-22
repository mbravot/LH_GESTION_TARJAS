import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class GlobalNotification extends StatelessWidget {
  final Widget child;

  const GlobalNotification({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        return Stack(
          children: [
            child!,
            if (notificationProvider.show)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 10,
                right: 10,
                child: _buildNotificationCard(notificationProvider),
              ),
          ],
        );
      },
      child: child,
    );
  }

  Widget _buildNotificationCard(NotificationProvider provider) {
    Color backgroundColor;
    Color textColor;
    IconData icon;

    switch (provider.type) {
      case 'success':
        backgroundColor = Colors.green;
        textColor = Colors.white;
        icon = Icons.check_circle;
        break;
      case 'error':
        backgroundColor = Colors.red;
        textColor = Colors.white;
        icon = Icons.error;
        break;
      case 'warning':
        backgroundColor = Colors.orange;
        textColor = Colors.white;
        icon = Icons.warning;
        break;
      default:
        backgroundColor = Colors.blue;
        textColor = Colors.white;
        icon = Icons.info;
    }

    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                provider.message ?? '',
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              onPressed: () => provider.hideNotification(),
              icon: Icon(Icons.close, color: textColor, size: 20),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
